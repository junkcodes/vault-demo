package main

import (
	"context"
	"errors"

	vault "github.com/hashicorp/vault/api"
)

func requestVault(address, token, mountPath, secretPath string) (*vault.KVSecret, error) {
	if address == "" {
		return nil, errors.New("Please set the VAULT_ADRESS env variable properly")
	} else if token == "" {
		return nil, errors.New("Please set the VAULT_TOKEN env variable properly")
	}
	config := vault.DefaultConfig()
	config.Address = address

	client, err := vault.NewClient(config)
	if err != nil {
		return nil, err
	}

	client.SetToken(token)
	secret, err := client.KVv1(mountPath).Get(context.Background(), secretPath)
	if err != nil {
		return nil, err
	}
	return secret, nil
}
