// lang-demo.js -- the playground for Lesson 12 (completion + LSP).
// Deliberate TODO markers here give Lesson 6's quickfix something to find.

const greeting = 'hello from the advanced vim tutor';

function announce(msg) {
  console.log(greeting + ': ' + msg);
}

function fail(msg) {
  console.error(msg);
  // TODO: return a real error object instead of just logging
}

announce('lesson 12');
// TODO: put the cursor on console.log above and press K for hover docs.
// TODO: gd jumps to its definition; Ctrl-O walks you back home.
// TODO: gr on `announce` lists every reference; rename with <leader>rn.

module.exports = { announce, fail };
