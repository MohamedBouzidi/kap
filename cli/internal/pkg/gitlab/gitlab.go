package gitlab

import (
	"log"
	"sync"
	"net/http"
	"crypto/tls"
	"crypto/x509"

	"github.com/xanzy/go-gitlab"
	"github.com/MohamedBouzidi/kapctl/internal/pkg/kubernetes"
)

func createGitlabHTTPClient(gitlabCAPEM []byte) *http.Client {
	// caCert, err := x509.ParseCertificate(gitlabCAPEM)
	// if err != nil {
	// 	log.Fatalf("Could not parse certificate: %v", err)
	// }
	certPool := x509.NewCertPool()
	certPool.AppendCertsFromPEM(gitlabCAPEM)
	// certPool.AddCert(caCert)
	client := &http.Client{
		Transport: &http.Transport{
			TLSClientConfig: &tls.Config{
				RootCAs: certPool,
			},
		},
	}

	return client
}

func createGitlabClient() (client *gitlab.Client, err error) {
	log.Printf("Building HTTP Client")
	gitlabCAPEM, err := kubernetes.GetSecretValue("gitlab", "gitlab-ca-secret", "ca.crt")
	if err != nil {
		log.Fatalf("Could not retrieve Gitlab CA: %v", err)
	}
	gitlabRootPassword, err := kubernetes.GetSecretValue("gitlab", "gitlab-gitlab-initial-root-password", "password")
	if err != nil {
		log.Fatalf("Could not retieve Gitlab password: %v", err)
	}
	httpClient := createGitlabHTTPClient(gitlabCAPEM)

	log.Printf("Authenticating with Gitlab")
	git, err := gitlab.NewBasicAuthClient(
		"root",
		string(gitlabRootPassword),
		gitlab.WithHTTPClient(httpClient),
		gitlab.WithBaseURL("https://gitlab.dev.local:9443"),
	)

	return git, err
}

func CreateGroup(groupName string) (groupID int, namespaceID int) {
	git, err := createGitlabClient()
	if err != nil {
		log.Fatal(err)
	}

	// Create new group
	p := &gitlab.CreateGroupOptions{
		Name:               gitlab.String(groupName),
		Path:               gitlab.String(groupName),
	}
	group, _, err := git.Groups.CreateGroup(p)
	if err != nil {
		log.Fatal(err)
	}

	log.Printf("Group created: %d", group.ID)
	
	namespace, _, err := git.Namespaces.GetNamespace(group.ID)
	if err != nil {
		log.Fatal(err)
	}

	return group.ID, namespace.ID
}

func CreateProject(projectName string, projectDescription string, namespaceID int) {
	git, err := createGitlabClient()
	if err != nil {
		log.Fatal(err)
	}

	// Create new project
	p := &gitlab.CreateProjectOptions{
		Name:                 gitlab.String(projectName),
		Description:          gitlab.String(projectDescription),
		NamespaceID:          gitlab.Int(namespaceID),
		MergeRequestsEnabled: gitlab.Bool(true),
		SnippetsEnabled:      gitlab.Bool(true),
		Visibility:           gitlab.Visibility(gitlab.PublicVisibility),
	}
	project, _, err := git.Projects.CreateProject(p)
	if err != nil {
		log.Fatal(err)
	}

	log.Printf("Project created: %d", project.ID)
}

func CreateUser(userName string, userEmail string, userPassword string, groupID int) {
	git, err := createGitlabClient()
	if err != nil {
		log.Fatal(err)
	}

	skipConfirmation := true

	// Create new user
	u := &gitlab.CreateUserOptions{
		Name:             gitlab.String(userName),
		Username:         gitlab.String(userName),
		Email:            gitlab.String(userEmail),
		Password:         gitlab.String(userPassword),
		SkipConfirmation: &skipConfirmation,
	}
	user, _, err := git.Users.CreateUser(u)
	if err != nil {
		log.Fatal(err)
	}

	log.Printf("User created: %d", user.ID)

	// Add user to group
	g := &gitlab.AddGroupMemberOptions{
		UserID:        gitlab.Int(user.ID),
		AccessLevel:   gitlab.AccessLevel(gitlab.OwnerPermissions),
		ExpiresAt:     nil,
	}
	member, _, err := git.GroupMembers.AddGroupMember(groupID, g)
	if err != nil {
		log.Fatal(err)
	}

	log.Printf("Member created: %d", member.ID)
}

func findGroupByName(groupName string) (id int) {
	git, err := createGitlabClient()
	if err != nil {
		log.Fatal(err)
	}

	// Find group
	groups, response, err := git.Groups.SearchGroup(groupName)
	if err != nil {
		log.Fatal(err)
	}

	if response.StatusCode != 200 {
		log.Fatal("Could not find group with name %s: %d", groupName, response.StatusCode)
	}

	if len(groups) > 1 {
		log.Fatal("Found more than one group with name %s", groupName)
	}

	return groups[0].ID
}

func DeleteGroup(groupName string) {
	git, err := createGitlabClient()
	if err != nil {
		log.Fatal(err)
	}

	groupId := findGroupByName(groupName)

	// Delete group
	log.Printf("Deleting Group: %s (%d)...", groupName, groupId)
	response, err := git.Groups.DeleteGroup(*gitlab.Int(groupId))
	if err != nil {
		log.Fatal(err)
	}

	if response.StatusCode == http.StatusAccepted {
		log.Print("Group deleted")
	}

	// Delete group members
	members, _, err := git.Groups.ListGroupMembers(groupName, nil)
	if err != nil {
		log.Fatal(err)
	}
	var wg sync.WaitGroup = sync.WaitGroup{}
	for _, member := range members {
		wg.Add(1)
		go func() {
			defer wg.Done()
			log.Printf("Deleting User: %d...", member.ID)
			_, err := git.Users.DeleteUser(member.ID)
			if err != nil {
				log.Fatal(err)
			}
			log.Printf("User %d deleted", member.ID)
		}()
	}
	wg.Wait()
}

func DeleteProject(projectName string) {
	git, err := createGitlabClient()
	if err != nil {
		log.Fatal(err)
	}

	// Delete project
	log.Printf("Deleting Project %s...", projectName)
	response, err := git.Projects.DeleteProject(*gitlab.String(projectName + "/" + projectName))
	if err != nil {
		log.Fatal(err)
	}

	log.Printf("Project deleted: %d", response.StatusCode)
}