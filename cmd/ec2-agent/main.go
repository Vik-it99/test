package main

import (
	"log"
	"os"

	"github.com/C2Devel/ec2-agent/internal/imds"
	"github.com/C2Devel/ec2-agent/internal/user"
)

func main() {
	logger := log.New(os.Stdout, "", log.LstdFlags)

	meta, err := imds.NewClient().Fetch()
	if err != nil {
		logger.Printf("failed to fetch metadata from IMDS: %v", err)
		os.Exit(1)
	}

	if meta.SSHKey == "" && meta.Password == "" {
		return
	}

	if meta.Username == "" {
		meta.Username = "ec2-user"
	}

	manager := user.NewManager()

	if err := manager.EnsureUser(meta.Username); err != nil {
		logger.Printf("failed to ensure user %q: %v", meta.Username, err)
		os.Exit(1)
	}

	if err := manager.EnsureSudoer(meta.Username); err != nil {
		logger.Printf("failed to ensure sudoer %q: %v", meta.Username, err)
		os.Exit(1)
	}

	if err := manager.SetupPassword(meta.Username, meta.Password); err != nil {
		logger.Printf("failed to setup password for %q: %v", meta.Username, err)
		os.Exit(1)
	}

	if err := manager.SetupSSHKey(meta.Username, meta.SSHKey); err != nil {
		logger.Printf("failed to setup ssh key for %q: %v", meta.Username, err)
		os.Exit(1)
	}

	logger.Printf("login credentials setup completed successfully for %q", meta.Username)
}
