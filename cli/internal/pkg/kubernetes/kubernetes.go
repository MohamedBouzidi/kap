package kubernetes

import (
	"context"
	"os"
	"log"
	"strings"
	"path/filepath"
	"io/ioutil"

	"k8s.io/apimachinery/pkg/runtime"
	"k8s.io/apimachinery/pkg/api/errors"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes/scheme"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
	"k8s.io/client-go/util/homedir"
)

func getClient() (client *kubernetes.Clientset) {
	var home string = homedir.HomeDir()
	var kubeconfig string = filepath.Join(home, ".kube", "config")

	// use the current context in kubeconfig
	config, err := clientcmd.BuildConfigFromFlags("", kubeconfig)
	if err != nil {
		panic(err.Error())
	}

	// create the clientset
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		panic(err.Error())
	}

	return clientset
}

func GetSecretValue(namespace string, secretName string, secretKey string) (secretValue []byte, err error) {
	clientset := getClient()
	secret, err := clientset.CoreV1().Secrets(namespace).Get(context.TODO(), secretName, metav1.GetOptions{})
	if errors.IsNotFound(err) {
		log.Fatalf("Secret %s in namespace %s not found\n", secretName, namespace)
	} else if statusError, isStatus := err.(*errors.StatusError); isStatus {
		log.Fatalf("Error getting secret %s in namespace %s: %v\n", secretName, namespace, statusError.ErrStatus.Message)
	} else if err != nil {
		panic(err.Error())
	} else {
		return secret.Data[secretKey], nil
	}
	return nil, err
}

func ReadYamlFile(filename string) []runtime.Object {
	path, err := os.Getwd()
	if err != nil {
		log.Fatal(err)
	}
	filebytes, err := ioutil.ReadFile(filepath.Join(path, "configs", filename))
	if err != nil {
		log.Fatal(err)
	}
	yamlFile := string(filebytes)
	yamlResources := strings.Split(yamlFile, "---")
	var resources []runtime.Object

	for _, resource := range yamlResources {
		resource = strings.Trim(resource, " ")
		resource = strings.Trim(resource, "\n")
		if resource == "\n" || resource == "" {
			continue
		}
		decode := scheme.Codecs.UniversalDeserializer().Decode
		obj, _, err := decode([]byte(resource), nil, nil)
		if err != nil {
			log.Fatal(err)
			continue
		}
		resources = append(resources, obj)
	}

	log.Print(resources)

	return resources
}