extern crate clap;
extern crate i3ipc;
use i3ipc::I3Connection;

fn main() {
    let app = clap::App::new("i3switcher")
        .about("Provides a smarter workspace switcher for i3")
        .author("Robin M.")
        .arg(
            clap::Arg::with_name("DIRECTION")
                .required(true)
                .help("Sets the direction switch in")
                .possible_values(&["prev", "next"]),
        )
        .arg_from_usage(
            "-m, --move-container 'moves the container to the workspace'",
        );

    let matches = app.get_matches();
    let direction = match matches.value_of("DIRECTION") {
        Some("prev") => -1,
        Some("next") => 1,
        _ => unreachable!(), // Clap should take care of this
    };

    let move_container = matches.is_present("move-container");

    // establish a connection to i3 over a unix socket
    let mut i3 = I3Connection::connect().expect("Could not connect to running i3 instance");

    let workspaces = i3.get_workspaces()
        .expect("Could not get list of workspaces from i3")
        .workspaces;

    if let Some(current_workspace) =
        i3.get_outputs()
            .expect("Failed to get list of outputs from i3")
            .outputs
            .into_iter()
            .find(|output| output.active)
            .and_then(|output| output.current_workspace)
    {
        println!("{}", current_workspace);

        let idx = workspaces.iter().find(|workspace| workspace.name == current_workspace).map(|workspace| workspace.num).expect("Could not find active workspace in the list of workspaces. This should not happen?");

        let mut next = idx + direction;
        if next < 1 {
            next = 1;
        }

        if move_container {
            i3.command(&format!("move container to workspace {}", next))
                .expect("Failed to move the container to the target workspace");
        }

        i3.command(&format!("workspace {}", next)).expect(
            "Failed to move to the target workspace",
        );

    } else {
        panic!("Could not find active output?")
    }

}
