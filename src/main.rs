use anyhow::{bail, Error};
use clap::Parser;
use i3ipc::{reply::Workspace, I3Connection};

#[derive(Debug, Copy, Clone, PartialEq, Eq, PartialOrd, Ord)]
pub enum Direction {
    Prev,
    Next,
}

impl std::str::FromStr for Direction {
    type Err = Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "previous" => Ok(Self::Prev),
            "next" => Ok(Self::Next),
            _ => bail!("expected \"next\" or \"previous\", but got \"{s}\""),
        }
    }
}

fn find_next(current_idx: usize, workspaces: &[Workspace], direction: Direction) -> Option<String> {
    match (current_idx, direction) {
        // If we are the first workspace, we don't need to move anywere, so don't do anything
        (0, Direction::Prev) => None,
        (_, Direction::Prev) => {
            let iter = workspaces.iter().rev().skip(workspaces.len() - current_idx);

            match iter.clone().find(|workspace| !workspace.visible) {
                Some(target) => Some(target.name.clone()),
                // If we couldn't find a workspace that's not already visible before idx,
                // then try to create a new workspace before the current one, but after the named
                // workspaces
                None => match iter
                    // Filter out all the named workspaces, which have num < 0
                    .filter(|workspace| workspace.num >= 0)
                    .last()
                {
                    // If the last workspace has a num > 0, then we can create a new workspace
                    // before it
                    Some(last) => {
                        if last.num > 0 {
                            Some((last.num - 1).to_string())
                        } else {
                            // Otherwise, we can't move anywere without changing what screens things
                            // are on, so don't move
                            None
                        }
                    }
                    // There are no other workspaces, so we are the lowest
                    None => {
                        if workspaces[current_idx].num > 0 {
                            // We are not the last workspace before the named workspaces start, and
                            // there are no others, so we can create a new one and move to it
                            Some((workspaces[current_idx].num - 1).to_string())
                        } else {
                            // We are the 0th workspace, so we can't create any new ones, and we can't move
                            // to the named ones because that move change what screen they're on, or they
                            // don't exist, so we don't do anything
                            None
                        }
                    }
                },
            }
        }
        (_, Direction::Next) => {
            let last_workspace = workspaces
                .iter()
                .last()
                .expect("Could not find last workspace");

            match workspaces
                .iter()
                .skip(current_idx)
                .find(|workspace| !workspace.visible)
            {
                Some(target) => Some(target.name.clone()),
                // If we couldn't find a workspace that's not already visible,
                // create a new one after the last workspace
                None => Some((last_workspace.num + 1).to_string()),
            }
        }
    }
}

#[derive(Debug, Parser)]
#[clap(author, version, about)]
struct Cli {
    direction: Direction,

    #[clap(long, short, aliases = &["move-container"])]
    move_focused_container: bool,
}

fn main() {
    let Cli {
        direction,
        move_focused_container,
    } = Cli::parse();

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
    let (idx_focused_workspace, focused_workspace) = workspaces
        .iter()
        .enumerate()
        .find(|(_, workspace)| workspace.focused)
        .expect("Could not find a focused workspace");

    // find the name of the workspace to switch to
    if let Some(target) = find_next(idx_focused_workspace, &workspaces, direction) {
        if move_focused_container {
            i3.run_command(&format!("move container to workspace {target}"))
                .expect("Failed to move the container to the target workspace");
        }

        i3.run_command(&format!("workspace {target}"))
            .expect("Failed to move to the target workspace");

        i3.run_command(&format!(
            "move workspace to output \"{}\"",
            focused_workspace.output
        ))
        .expect("Failed to move to the target workspace");
    }
}
