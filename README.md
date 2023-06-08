# TBot Telegram Bot

This is a telegram bot 

[![TBOT-CICD](https://github.com/EvgenPavlyuchek/tbot/actions/workflows/cicd.yml/badge.svg)](https://github.com/EvgenPavlyuchek/tbot/actions/workflows/cicd.yml)

# CI/CD

![CICD](https://github.com/EvgenPavlyuchek/tbot/blob/main/cicd.jpg)

# Installation

1. Clone repository : `git clone`
2. Create new bot in Telegram
3. Add into project bot's token variable TELE_TOKEN
4. Build project with 'go build -ldflags "-X="github.com/EvgenPavlyuchek/tbot/cmd.appVersion=v1.0.3-linux-amd64
5. Run './tbot start'

# Using

You can send comands in bot
- /start
- /help 
- /start start
- /start help
