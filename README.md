# Glemail Client

Wildduck CLI Email Client Written in Gleam

## Why?

Because it's fun to code `:)`

## Running

Remember to [setup your env file](#env). You will also need your own wildduck instance, I recommend using [Wildduck-Dockerized](https://github.com/nodemailer/wildduck-dockerized).

```sh
gleam run mailboxes list # list available mailboxes

gleam run inbox 10 1 # get 10 messages from your inbox at page 1
# or alternatively
gleam run drafts list 5 on page 1 # for a more human-like command (from drafts mailbox)
```

## Development

### Env

```
API_URL=https://yourserver.com
ACCESS_TOKEN=superspecialsecretaccesstoken
USER_ID=wildduckuserid
```
