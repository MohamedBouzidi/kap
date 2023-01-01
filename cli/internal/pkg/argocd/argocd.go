package argocd

import (
	"github.com/MohamedBouzidi/kapctl/internal/pkg/kubernetes"
	"github.com/argoproj/argo-cd/pkg/apis/application/v1alpha1"
	"github.com/argoproj/argo-cd/pkg/apiclient"
)

func CreateProject() {
	argoProject := kubernetes.ReadYamlFile("project.yaml")[0]
	client := apiclient.NewProjectClient()
	p := apiclient.ProjectCreateRequest{
		Project:            &argoProject.(v1alpha1.AppProject),
		Upsert:             true,
	}
}