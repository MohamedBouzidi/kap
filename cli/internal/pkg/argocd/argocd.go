package argocd

import (
	"log"
	"context"

	// "github.com/MohamedBouzidi/kapctl/internal/pkg/kubernetes"
	"github.com/argoproj/argo-cd/pkg/apis/application/v1alpha1"
	"github.com/argoproj/argo-cd/pkg/apiclient"
	"github.com/argoproj/argo-cd/pkg/apiclient/project"
)

func CreateProject() {
	argoClientOptions := apiclient.ClientOptions{
		ServerAddr: "argocd.dev.local:9443",
		Insecure: true,
	}
	argoClient, err := apiclient.NewClient(&argoClientOptions)
	if err != nil {
		log.Fatalf("Could not connect to ArgoCD: %v", err)
	}
	
	closer, argoProjectClient, err := argoClient.NewProjectClient()
	if err != nil {
		log.Fatalf("Could not create ArgoCD client: %v", err)
	}
	defer closer.Close()

	// argoProjects, err := argoProjectClient.List(context.TODO(), &project.ProjectQuery{})
	// if err != nil {
	// 	log.Fatalf("Could not list ArgoCD projects: %v", err)
	// }
	// log.Printf("%v", argoProjects.Items)

	// argoProject := kubernetes.ReadYamlFile("project.yaml")[0]
	// log.Printf("Read project definition file")
	argoProject := &v1alpha1.AppProject{
		// Name: "test-app",
		// Namespace: "default",
		Spec: v1alpha1.AppProjectSpec{
			Description: "Example Project",
			SourceRepos: []string{ "*" },
			Destinations: []v1alpha1.ApplicationDestination{
				v1alpha1.ApplicationDestination{
					Server: "https://kubernetes.default.svc",
					Namespace: "default",
					// Name: '',
				},
			},
		},
	}
	createdArgoProject, err := argoProjectClient.Create(context.TODO(), &project.ProjectCreateRequest{
		Project:   argoProject,
		Upsert: true,
	})
	if err != nil {
		log.Fatalf("Could not create ArgoCD project: %v", err)
	}
	log.Printf("Argo Project %s created.", createdArgoProject.Name)
}