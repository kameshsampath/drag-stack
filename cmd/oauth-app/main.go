package main

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"flag"
	"fmt"
	"log"

	"code.gitea.io/sdk/gitea"
	apiv1 "k8s.io/api/core/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/rest"
)

var (
	oAuthAppName       string
	droneHostURL       string
	giteaAdminPassword string
	giteaAdminUser     string
	giteaUrl           string
	namespace          string
)

func main() {

	flag.StringVar(&oAuthAppName, "a", "dag-demos", "The Gitea oAuth Application Name")
	flag.StringVar(&droneHostURL, "dh", "http://drone-127.0.0.1.sslip.io:8080", "The Drone Host URL")
	flag.StringVar(&giteaAdminUser, "u", "demo", "The Gitea admin username")
	flag.StringVar(&giteaAdminPassword, "p", "demo@123", "The Gitea admin user password")
	flag.StringVar(&giteaUrl, "g", "http://gitea-http.default:3000", "The Gitea URL")
	flag.StringVar(&namespace, "n", "drone", "The kubernetes namespace where to create the oauth client secret")
	flag.Parse()

	c, err := gitea.NewClient(giteaUrl)
	c.SetBasicAuth(giteaAdminUser, giteaAdminPassword)
	if err != nil {
		log.Fatalln(err)
	}

	oAuthApps, _, err := c.ListOauth2(gitea.ListOauth2Option{})

	if err != nil {
		log.Fatalln(err)
	}

	var appExists = false
	var oAuthApp *gitea.Oauth2
	for _, oAuthApp = range oAuthApps {
		if oAuthApp.Name == oAuthAppName {
			appExists = true
			break
		}
	}

	if !appExists {
		log.Println("Creating new oAuth App")
		o, _, err := c.CreateOauth2(gitea.CreateOauth2Option{
			RedirectURIs: []string{fmt.Sprintf("%s/login", droneHostURL)},
			Name:         oAuthAppName})
		if err != nil {
			log.Fatalln(err)
		}
		sec, _ := randomHex(16)

		config, err := rest.InClusterConfig()
		if err != nil {
			log.Fatalln(err)
		}
		log.Println("Got InCluster Config")

		clientset, err := kubernetes.NewForConfig(config)
		if err != nil {
			log.Fatalln(err)
		}
		log.Println("Got Client Set")

		_, err2 := clientset.CoreV1().Secrets(namespace).Create(context.TODO(), &apiv1.Secret{
			ObjectMeta: metav1.ObjectMeta{
				Name: fmt.Sprintf("%s-secret", oAuthAppName),
			},
			StringData: map[string]string{
				"DRONE_GITEA_CLIENT_ID":     o.ClientID,
				"DRONE_GITEA_CLIENT_SECRET": o.ClientSecret,
				"DRONE_RPC_SECRET":          sec,
			},
		}, metav1.CreateOptions{})

		if err2 != nil {
			log.Fatalln(err2)
		}
		log.Printf("Successfully created oAuth application %s", oAuthAppName)
	} else {
		log.Printf("\noAuth app %s already exists, updating", oAuthAppName)
		_, _, err := c.UpdateOauth2(oAuthApp.ID,
			gitea.CreateOauth2Option{
				RedirectURIs: []string{fmt.Sprintf("%s/login", droneHostURL)},
				Name:         oAuthAppName,
			})
		if err != nil {
			log.Fatalln(err)
		}
	}

}

func randomHex(n int) (string, error) {
	bytes := make([]byte, n)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	return hex.EncodeToString(bytes), nil
}
