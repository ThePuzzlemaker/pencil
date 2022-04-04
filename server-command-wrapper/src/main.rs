use std::env;
use std::process::{self, Stdio};
use tokio::io::{self, AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::process::Command;

use color_eyre::eyre;
use tokio::{join, select};

#[tokio::main]
async fn main() -> eyre::Result<()> {
    color_eyre::install()?;

    let mut args = env::args().skip(1);
    let java_path = args.next().unwrap();
    let java_args = args.collect::<Vec<_>>();

    let mut cmd = Command::new(java_path)
        .args(&java_args)
        .stdin(Stdio::piped())
        .spawn()?;

    let mut stdin = io::stdin();
    let mut child_stdin = cmd.stdin.take().unwrap();
    select! {
        _ = io::copy(&mut stdin, &mut child_stdin) => {
            true
        },
        Ok(exit) = cmd.wait() => {
            process::exit(exit.code().unwrap_or(127));
        }
    };
    child_stdin.write_all("stop\n".as_bytes()).await?;
    child_stdin.flush().await?;
    let exit = cmd.wait().await?;
    process::exit(exit.code().unwrap_or(127));
}
