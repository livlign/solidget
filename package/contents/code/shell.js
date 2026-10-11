.pragma library

// Plasma's "executable" engine runs a command line through the shell, so
// every argument must be quoted or it could run something else (a city
// called `x; rm -rf ~` would). Build commands only with command([...]).

// One argument, safe for sh: wrapped in single quotes, with any single
// quote inside written as '\'' (close, escaped quote, reopen).
function quote(arg) {
    return "'" + String(arg).replace(/'/g, "'\\''") + "'";
}

// ["notify-send", "--", title] -> 'notify-send' '--' 'title'
function command(args) {
    return args.map(quote).join(" ");
}
