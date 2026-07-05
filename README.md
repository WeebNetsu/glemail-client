# Glemail Client

Wildduck Email Client Written in Gleam

## Why?

Because it's fun to code `:)`

## Dependencies

| Program                                       | Cause                                                                                                                     |
| --------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| [Gleam](https://gleam.run/)                   | Program is written in Gleam, silly!                                                                                       |
| [Wildduck](https://docs.wildduck.email/)      | Mail server, I recommend using [Wildduck Dockerized](https://github.com/nodemailer/wildduck-dockerized) to simplify setup |
| [TypeScript](https://www.typescriptlang.org/) | To compile frontend JS modules                                                                                            |
| [Just](https://github.com/casey/just)         | Optional but makes it easy to run everything                                                                              |

## Running

Be sure you created your `.env` file in `src/backend`, and updated config.gleam in `src/frontend`.

```sh
just install # install dependencies
just build-ts # compiles ts files into js, will auto execute on start-frontend as well
just start-backend # start the backend
just start-frontend # start the frontend
```
