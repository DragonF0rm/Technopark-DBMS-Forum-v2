package database

import (
	"github.com/jackc/pgx"
	"log"
)

type dbManager struct {
	ConnPool*pgx.ConnPool
}

var manager *dbManager

func init() {
	pool, err := pgx.NewConnPool(poolConfig)
	if err != nil {
		log.Fatal(err)
	}

	manager = &dbManager {
		ConnPool: pool,
	}
}

func GetInstance() *dbManager {
	return manager
}

