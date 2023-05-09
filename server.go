package main

import (
	"database/sql"
	"fmt"
	"os"

	_ "github.com/lib/pq"
)

func main() {

	psqlDBcreds, err := requestVault(os.Getenv("VAULT_ADDRESS"), os.Getenv("VAULT_TOKEN"), "database", "creds/exampledb-pg")
	if err != nil {
		panic(err)
	}

	psqlInfo := fmt.Sprintf("host=%s port=%s user=%s "+
		"password=%s dbname=%s sslmode=disable",
		os.Getenv("DB_HOST_NAME"), os.Getenv("PORT"), psqlDBcreds.Data["username"], psqlDBcreds.Data["password"], os.Getenv("DB_NAME"))

	db, err := sql.Open("postgres", psqlInfo)
	if err != nil {
		panic(err)
	}
	defer db.Close()

	err = db.Ping()
	if err != nil {
		panic(err)
	}
	fmt.Println("Successfully connected!")
}
