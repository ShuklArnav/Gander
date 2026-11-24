/***********/
/* Imports */
/***********/

import slice_pool;
import slot_pool;

/*********************** Namespace `gander` ***********************/

namespace gander;

/***************************** The `Commmand` Interface *****************************/

/******************/
/* `Command` Type */
/******************/

/// Internal representation of commands
struct Command {
    name:      const u8[:],
    shortdesc: const u8[:],
    desc:      const u8[:],
    _commands: CommandLink[:],
    _options:  Option[:],
}

/// Reference to elements in `commandpool`
type CommandLink = Command&<u32 in commandpool.items>?;
/// A pool where new `Command`s are allocated
var commandpool = slot_pool<Command> {};
/// A pool where all `Command`s live
var commands = slice_pool<CommandLink> {};
/// The root `Command`
var cli: Command?;

/// Create a new `Command`
fn make(
    name:      const u8[:],
    shortdesc: const u8[:],
    desc:      const u8[:],
) -> Command& {
    commandpool.alloc_ref(Command {
        name:      name,
        shortdesc: shortdesc,
        desc:      desc,
        _commands: commands.alloc_slice(0),
        _options:  options.alloc_slice(0),
    })
}

/**********************/
/* The Root `Command` */
/**********************/

/// Create the root `Command`
fn CLI(
    name: const u8[:],
    desc: const u8[:] = "",
) -> Command& {
    cli .= make(name, "", desc);
    cli
}

/// Create the root `Command` from an enum type
fn CLI<T>(
    name: const u8[:],
    desc: const u8[:] = "",
) -> Command& {
    CLI(name, desc).command<T>()
}

/**********************/
/* The Sub-`Command`s */
/**********************/

/// Add a sub-`Command` to a `Command`
fn command(
    command:   Command&,
    name:      const u8[:],
    shortdesc: const u8[:] = "",
    desc:      const u8[:] = "",
) -> Command& {
    let c .= make(name, shortdesc, desc);
    let k = command._commands.len;
    command._commands = commands.realloc_slice(command._commands, k + 1);
    command._commands[k] .= c;
    c
}

/// Recursively create a sub-`Command` from an
/// enum type to a `Command`
recursive fn command<T>(com: Command&) -> Command& {
    const for <NAME, COMMAND> in variants<T> {
        let command = COMMAND { .. };

        let shortdesc: const u8[:];
        let desc:      const u8[:];
        let options:   const Option[:];

        const for <PROP, _> in fields<COMMAND> {
            const if PROP == "shortdesc" {
                shortdesc = command.shortdesc;
            } else const if PROP == "desc" {
                desc = command.desc;
            } else const if PROP == "options" {
                options .= command.options;
            }
        }

        let comm .= com.command(NAME, shortdesc, desc);
        const for <PROP, _, TYPE> in fields<COMMAND> {
            const if PROP == "commands" {
                comm.command<TYPE>();
            } const if PROP == "options" {
                for o in options {
                    comm.option(o.name, o.desc);
                }
            }
        }
    }

    com
}

/***********/
/* Running */
/***********/

/// Find the sub-command named `name` below `command`
fn find(command: Command&, name: const u8[:]) -> Command? {
    for c in command._commands {
        assert(c);
        if c.name == name { return c; }
    }
    null
}

/// A value of the root enum type, for its `exec`
fn root<T>() -> T {
    const for <NAME, VARIANT> in variants<T> {
        return VARIANT { .. };
    }
    abort("cannot run an enum without variants");
}

/// Dispatch the arguments below a command of type `T`
recursive fn dispatch<T>(
    command: Command&,
    args:    const (const u8[:])[:],
    next:    i64,
) -> bool {
    const for <NAME, VARIANT> in variants<T> {
        if command.name == NAME {
            if next < args.len {
                if args[next] == "--help" || args[next] == "-h" {
                    print(command);
                    return true;
                }
            }
            exec(VARIANT { .. });
            if next < args.len {
                const for <PROP, _, TYPE> in fields<VARIANT> {
                    const if PROP == "commands" {
                        if dispatchCommand<TYPE>(command, args[next], args, next + 1) {
                            return true;
                        }
                    }
                }
            }
            return true;
        }
    }
    false
}

/// Find the sub-command named `name` and dispatch below it
recursive fn dispatchCommand<T>(
    command: Command&,
    name:    const u8[:],
    args:    const (const u8[:])[:],
    next:    i64,
) -> bool {
    let child = find(command, name);
    guard child else { return false; }
    dispatch<T>(child, args, next)
}

/// Run `command` with `args`
fn run<T>(command: Command&, args: const (const u8[:])[:]) {
    if args.len >= 2 && (args[1] == "--help" || args[1] == "-h") {
        print(command);
        return;
    }
    exec(root<T>());
    guard args.len >= 2 else { return; }
    let child = find(command, args[1]);
    guard child else {
        print(command);
        return;
    }
    dispatch<T>(child, args, 2);
}

/***************************/
/* Formatting and Printing */
/***************************/

/// Recursively list all commands
/// and print them
recursive fn list(command: gander::Command, depth: i64, out: u8[>..]&) {
    for i in depth { format(out, "    "); }
    format(out, command.name, "    ", command.shortdesc, "\n");
    for i in command._commands {
        assert(i);
        list(i, depth + 1, out);
    }
    for o in command._options {
        for i in depth + 1 { format(out, "    "); }
        format(out, "--", o.name, "    ", o.desc, "\n");
    }
}

/// Overload print(Command)
/// and print(Command&)
fn format(out: u8[>..]&, command: gander::Command) {
    var buf: u8[>..] = [];
    list(command, 0, buf);
    format(out, buf);
}

/***************************** The `Commmand` Interface *****************************/

/*************************** The `Option` Interface ***************************/

/// Internal representation of options and flags
struct Option {
    const name: u8[:],
    const desc: u8[:],
}

/// A pool where all `Option`s live
var options = slice_pool<Option> {};

/// Add a new Option to a Command
fn option(
    command: Command&,
    name:    const u8[:],
    desc:    const u8[:] = "",
) -> Command& {
    let k = command._options.len;
    command._options = options.realloc_slice(command._options, k + 1);
    command._options[k] = Option { name, desc };
    command
}

/*************************** The `Option` Interface ***************************/

/*********************** Namespace `gander` ***********************/