package service

import (
	"github.com/DragonF0rm/Technopark-DBMS-Forum/database"
)

func clear()(err error) {
	conn, err := database.GetInstance().ConnPool.Acquire()
	defer database.GetInstance().ConnPool.Release(conn)
	tx, err := conn.Begin()
	if err != nil {
		return
	}
	defer tx.Rollback()

	_, err = tx.Exec(`SELECT * FROM func_service_clear()`)
	if err == nil {
		err = tx.Commit()
	}
	return
}
