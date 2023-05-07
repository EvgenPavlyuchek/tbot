/*
Copyright © 2023 NAME HERE <EMAIL ADDRESS>
*/
package cmd

import (
	"fmt"
	"github.com/spf13/cobra"
	telebot "gopkg.in/telebot.v3"
	"log"
	"os"
	"time"
)

var (
	// TeleToken bot
	TeleToken = os.Getenv("TELE_TOKEN")

	descriptionMsg = "Hello I'm Tbot " + appVersion + "!" +
		"\nYou can run commands below" +
		"\n/start - to start bot" +
		"\n/help - to see help" +
		"\nYou can also type such commands" +
		"\n/start start - to see some message" +
		"\n/start help - to see another message"
)

// tbotCmd represents the tbot command
var tbotCmd = &cobra.Command{
	Use:     "tbot",
	Aliases: []string{"start"},
	Short:   "A brief description of your command",
	Long: `A longer description that spans multiple lines and likely contains examples
and usage of using your command. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`,
	Run: func(cmd *cobra.Command, args []string) {

		fmt.Printf("tbot %s started", appVersion)
		tbot, err := telebot.NewBot(telebot.Settings{
			URL:    "",
			Token:  TeleToken,
			Poller: &telebot.LongPoller{Timeout: 10 * time.Second},
		})

		if err != nil {
			log.Fatalf("Plaese check TELE_TOKEN env variable. %s", err)
			return
		}
		/*
			tbot.Handle("/start", func(m telebot.Context) error {

				m.Send(descriptionMsg)

				return err
			})

			tbot.Handle("/help", func(m telebot.Context) error {

				m.Send(descriptionMsg)

				return err
			})
		*/

		tbot.Handle(telebot.OnText, func(m telebot.Context) error {

			log.Print(m.Message().Payload, m.Text())
			payload := m.Message().Payload
			payload2 := m.Text()

			switch payload {
			case "hello":
				err = m.Send(fmt.Sprintf("Hello I'm Tbot %s!", appVersion))
			case "start":
				err = m.Send(fmt.Sprintf("Start I'm Tbot %s!", appVersion))
			}

			switch payload2 {
			case "/start":
				err = m.Send(descriptionMsg)
			case "/help":
				err = m.Send(descriptionMsg)
			}

			return err

		})

		tbot.Start()
	},
}

func init() {
	rootCmd.AddCommand(tbotCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// tbotCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// tbotCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
}
