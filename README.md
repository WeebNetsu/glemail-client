# Glemail Client

Wildduck Email Client Written in Gleam

## Why?

Because it's fun to code `:)`

## Dependencies

| Program                                  | Cause                                                                                                                     |
| ---------------------------------------- | ------------------------------------------------------------------------------------------------------------------------- |
| [Gleam](https://gleam.run/)              | Program is written in Gleam, silly!                                                                                       |
| [Wildduck](https://docs.wildduck.email/) | Mail server, I recommend using [Wildduck Dockerized](https://github.com/nodemailer/wildduck-dockerized) to simplify setup |
| [Just](https://github.com/casey/just)    | Optional but makes it easy to run everything                                                                              |

## Running

Be sure you created your `.env` file in `src/backend`.

```sh
just install # install dependencies
just start-backend # start the backend
just start-frontend # start the frontend
```
