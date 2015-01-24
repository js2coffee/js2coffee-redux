{ replace } = require('../helpers')
TransformerBase = require('./base')

###
# Provides transformations for `while`, `for` and `do`.
###

module.exports =
class LoopTransforms extends TransformerBase
  ForStatement: (node) ->
    @injectUpdateIntoBody(node)
    @convertForToWhile(node)

  ForInStatement: (node) ->
    @warnIfNoVar(node)

  WhileStatement: (node) ->
    @convertWhileToLoop(node)

  DoWhileStatement: (node) ->
    @convertDoWhileToLoop(node)

  ###
  # Converts `do { x } while (y)` to `loop\  x\  break unless y`.
  ###

  convertDoWhileToLoop: (node) ->
    block = node.body
    body = block.body

    body.push replace node.test,
      type: 'IfStatement'
      _negative: true
      test: node.test
      consequent:
        type: 'BreakStatement'

    replace node,
      type: 'CoffeeLoopStatement'
      body: block

  ###
  # Produce a warning for `for (x in y)` where `x` is not `var x`.
  ###

  warnIfNoVar: (node) ->
    if node.left.type isnt 'VariableDeclaration'
      @warn node, "Using 'for..in' loops without " +
        "'var' can produce unexpected results"
    node

  ###
  # Converts a `for (x;y;z) {a}` to `x; while(y) {a; z}`.
  # Returns a `BlockStatement`.
  ###

  convertForToWhile: (node) ->
    node.type = 'WhileStatement'
    block =
      type: 'BlockStatement'
      body: [ node ]

    if node.init
      block.body.unshift
        type: 'ExpressionStatement'
        expression: node.init

    return block

  ###
  # Converts a `while (true)` to a CoffeeLoopStatement.
  ###

  convertWhileToLoop: (node) ->
    isLoop = not node.test? or
      (node.test?.type is 'Literal' and node.test?.value is true)

    if isLoop
      replace node,
        type: 'CoffeeLoopStatement'
        body: node.body
    else
      node

  ###*
  # Injects a ForStatement's update (eg, `i++`) into the body.
  ###

  injectUpdateIntoBody: (node) ->
    if node.update
      statement =
        type: 'ExpressionStatement'
        expression: node.update

      # Ensure that the body is a BlockStatement with a body
      if not node.body?
        node.body ?= { type: 'BlockStatement', body: [] }
      else if node.body.type isnt 'BlockStatement'
        old = node.body
        node.body = { type: 'BlockStatement', body: [ old ] }

      node.body.body = node.body.body.concat([statement])
      delete node.update
