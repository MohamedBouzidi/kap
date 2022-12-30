/*
Copyright © 2022 NAME HERE <EMAIL ADDRESS>

*/
package cmd

import (
	"fmt"
	"log"

	"github.com/spf13/cobra"
	"github.com/MohamedBouzidi/kapctl/internal/pkg/gitlab"
)

// projectCmd represents the project command
var projectCmd = &cobra.Command{
	Use:   "project",
	Short: "A brief description of your command",
	Long: `A longer description that spans multiple lines and likely contains examples
and usage of using your command. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("project called")

		projectName, err := cmd.Flags().GetString("project-name")
		if err != nil {
			log.Fatal(err)
		}
		projectDescription, err := cmd.Flags().GetString("project-description")
		if err != nil {
			log.Fatal(err)
		}

		log.Printf("Creating project %s - %s...", projectName, projectDescription)
		gitlab.CreateProject(projectName, projectDescription)
	},
}

func init() {
	createCmd.AddCommand(projectCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// projectCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// projectCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
	projectCmd.Flags().String("project-name", "PROJECT NAME", "GitLab project name")
	projectCmd.Flags().String("project-description", "PROJECT DESCRIPTION", "Gitlab project description")
}