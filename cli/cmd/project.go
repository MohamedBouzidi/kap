/*
Copyright © 2022 NAME HERE <EMAIL ADDRESS>

*/
package cmd

import (
	"fmt"
	"log"

	"github.com/spf13/cobra"
	"github.com/MohamedBouzidi/kapctl/internal/pkg/gitlab"
	"github.com/MohamedBouzidi/kapctl/internal/pkg/argocd"
)

// projectCreateCmd represents the project command
var projectCreateCmd = &cobra.Command{
	Use:   "project",
	Short: "A brief description of your command",
	Long: `A longer description that spans multiple lines and likely contains examples
and usage of using your command. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the needed files
to quickly create a Cobra application.`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("project create called")

		projectName, err := cmd.Flags().GetString("project-name")
		if err != nil {
			log.Fatal(err)
		}
		projectDescription, err := cmd.Flags().GetString("project-description")
		if err != nil {
			log.Fatal(err)
		}
		projectUserName, err := cmd.Flags().GetString("project-user")
		if err != nil {
			log.Fatal(err)
		}
		projectUserEmail, err := cmd.Flags().GetString("project-user-email")
		if err != nil {
			log.Fatal(err)
		}
		projectUserInitialPassword, err := cmd.Flags().GetString("project-user-initial-password")
		if err != nil {
			log.Fatal(err)
		}

		log.Printf("Creating project %s - %s...", projectName, projectDescription)
		log.Print(projectUserName, projectUserEmail, projectUserInitialPassword)
		// groupID, namespaceID := gitlab.CreateGroup(projectName)
		// gitlab.CreateProject(projectName, projectDescription, namespaceID)
		// gitlab.CreateUser(projectUserName, projectUserEmail, projectUserInitialPassword, groupID)
		argocd.CreateProject()
	},
}

var projectDeleteCmd = &cobra.Command{
	Use:   "project",
	Short: "A brief description of your command",
	Long: `A longer description that spans multiple lines and likely contains examples
and usage of using your command. For example:

Cobra is a CLI library for Go that empowers applications.
This application is a tool to generate the need files
to quickly create a Cobra application.`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("project delete called")

		projectName, err := cmd.Flags().GetString("project-name")
		if err != nil {
			log.Fatal(err)
		}

		log.Printf("Deleting project %s...", projectName)
		gitlab.DeleteProject(projectName)
		gitlab.DeleteGroup(projectName)
	},
}

func init() {
	createCmd.AddCommand(projectCreateCmd)
	deleteCmd.AddCommand(projectDeleteCmd)

	// Here you will define your flags and configuration settings.

	// Cobra supports Persistent Flags which will work for this command
	// and all subcommands, e.g.:
	// projectCreateCmd.PersistentFlags().String("foo", "", "A help for foo")

	// Cobra supports local flags which will only run when this command
	// is called directly, e.g.:
	// projectCreateCmd.Flags().BoolP("toggle", "t", false, "Help message for toggle")
	projectCreateCmd.Flags().String("project-name", "PROJECT NAME", "GitLab project name")
	projectCreateCmd.Flags().String("project-description", "PROJECT DESCRIPTION", "Gitlab project description")
	projectCreateCmd.Flags().String("project-user", "PROJECT USER", "GitLab project user")
	projectCreateCmd.Flags().String("project-user-email", "PROJECT USER EMAIL", "GitLab project user email")
	projectCreateCmd.Flags().String("project-user-initial-password", "PROJECT USER INITIAL PASSWORD", "GitLab project user initial password")

	projectDeleteCmd.Flags().String("project-name", "PROJECT NAME", "Gitlab project name")
}