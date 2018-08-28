extern crate clap;
extern crate i3ipc;
use i3ipc::{reply::Workspace, I3Connection};

#[derive(Debug, Copy, Clone, PartialEq, Eq, PartialOrd, Ord)]
pub enum Direction {
    Prev,
    Next,
}

fn find_next(idx: usize, slice: &[Workspace], direction: Direction) -> String {
    let search_iter: Box<Iterator<Item = &Workspace>> = match direction {
        Direction::Next => Box::new(slice[idx..].iter()),
        Direction::Prev => Box::new(slice[..=idx].iter().rev()),
    };

    let mut search_iter = search_iter.peekable();

    loop {
        match (search_iter.next(), search_iter.peek()) {
            (Some(prev_workspace), Some(current_workspace)) => {
                if direction == Direction::Next
                    && prev_workspace.num != -1
                    && prev_workspace.num + 1 < current_workspace.num
                {
                    break (prev_workspace.num + 1).to_string();
                } else if direction == Direction::Prev
                    && current_workspace.num != -1
                    && prev_workspace.num - 1 > current_workspace.num
                {
                    break (prev_workspace.num - 1).to_string();
                } else if !current_workspace.visible {
                    break current_workspace.name.clone();
                }
            }
            (Some(prev_workspace), None) => match direction {
                Direction::Next => {
                    break if prev_workspace.num == -1 {
                        "1".to_string()
                    } else {
                        (prev_workspace.num + 1).to_string()
                    }
                }
                Direction::Prev => {
                    break if prev_workspace.num == -1 {
                        break prev_workspace.name.clone();
                    } else {
                        (prev_workspace.num - 1).to_string()
                    }
                }
            },
            _ => unreachable!(),
        }
    }
}

fn main() {
    let app = clap::App::new("i3switcher")
        .about("Provides a smarter workspace switcher for i3")
        .author("Robin M.")
        .arg(
            clap::Arg::with_name("DIRECTION")
                .required(true)
                .help("Sets the direction switch in")
                .possible_values(&["prev", "next"]),
        ).arg_from_usage("-m, --move-container 'moves the container to the workspace'");

    let matches = app.get_matches();
    let direction = match matches.value_of("DIRECTION") {
        Some("prev") => Direction::Prev,
        Some("next") => Direction::Next,
        _ => unreachable!(), // Clap should take care of this
    };

    let move_container = matches.is_present("move-container");

    // establish a connection to i3 over a unix socket
    let mut i3 = I3Connection::connect().expect("Could not connect to running i3 instance");

    let (mut named_workspaces, mut numbered_workspaces): (Vec<_>, Vec<_>) = i3
        .get_workspaces()
        .expect("Could not get list of workspaces from i3")
        .workspaces
        .into_iter()
        .partition(|workspace| workspace.num == -1);

    // Make sure that the workspaces are in the correct order
    named_workspaces.sort_by(|a, b| a.name.cmp(&b.name));
    numbered_workspaces.sort_by_key(|workspace| workspace.num);

    // Merge the ordered lists of workspaces
    let mut workspaces = named_workspaces;
    workspaces.extend(numbered_workspaces);

    // find the index of the focused workspace
    let idx_focused_workspace = workspaces
        .iter()
        .position(|workspace| workspace.focused)
        .expect("Could not find a focused workspace");

    // find the name of the workspace to switch to
    let target = find_next(idx_focused_workspace, &workspaces, direction);

    if move_container {
        i3.run_command(&format!("move container to workspace {}", target))
            .expect("Failed to move the container to the target workspace");
    }

    i3.run_command(&format!("workspace {}", target))
        .expect("Failed to move to the target workspace");
}
