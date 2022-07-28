package main

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path"

	"code.gitea.io/sdk/gitea"
)

var (
	oAuthAppName       string
	droneHostURL       string
	giteaAdminPassword string
	giteaAdminUser     string
	giteaUrl           string
	giteaRepoName      string
	githubTemplateRepo string
	repoNotExists      = errors.New("404 Not Found")
)

func main() {

	flag.StringVar(&oAuthAppName, "a", "dag-demos", "The Gitea oAuth Application Name")
	flag.StringVar(&droneHostURL, "dh", "http://drone-127.0.0.1.sslip.io:8080", "The Drone Host URL")
	flag.StringVar(&giteaAdminUser, "u", "demo", "The Gitea admin username")
	flag.StringVar(&giteaAdminPassword, "p", "demo@123", "The Gitea admin user password")
	flag.StringVar(&giteaUrl, "g", "http://gitea.default:3000", "The Gitea URL")
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
		o, _, err := c.CreateOauth2(gitea.CreateOauth2Option{
			RedirectURIs: []string{fmt.Sprintf("%s/login", droneHostURL)},
			Name:         oAuthAppName})
		if err != nil {
			log.Fatalln(err)
		}
		cwd, _ := os.Getwd()
		sec, _ := randomHex(16)
		ioutil.WriteFile(path.Join(cwd, "k8s", ".env"), []byte(fmt.Sprintf(`DRONE_GITEA_CLIENT_ID=%s
DRONE_GITEA_CLIENT_SECRET=%s
DRONE_RPC_SECRET=%s
`, o.ClientID, o.ClientSecret, sec)), 0600)
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
