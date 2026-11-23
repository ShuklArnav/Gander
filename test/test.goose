import gander from "..";

enum CLI {
    command1 {
        shortdesc: const u8[:] = "",
        desc:      const u8[:] = "",
        commands:  Command1,
        options:   FiveOptions = [gander::Option { "Some", "" }],
    },
    command2 {
        shortdesc: const u8[:] = "",
        desc:      const u8[:] = "",
    },
}

enum Command1 {
    subcommand1 {
        shortdesc: const u8[:] = "",
        desc:      const u8[:] = "",
    },
    subcommand2 {
        shortdesc: const u8[:] = "",
        desc:      const u8[:] = "",
    },
}

fn main() {
    let cli .= gander::CLI<CLI>("goose", "The Goose runtime");
    print(cli)
}
