package user

import (
	"github.com/DragonF0rm/Technopark-DBMS-Forum/database"
	"github.com/DragonF0rm/Technopark-DBMS-Forum/responses"
	"github.com/jackc/pgx"
)

func create(nickname, fullname, about, email string)(code int, response interface{}) {
	conn, err := database.GetInstance().ConnPool.Acquire()
	defer database.GetInstance().ConnPool.Release(conn)
	tx, err := conn.Begin()
	if err != nil {
		return responses.InternalError("Error while starting transaction: " + err.Error())
	}
	defer tx.Rollback()

	var rows *pgx.Rows
	rows, err = tx.Query(`SELECT * FROM func_user_create($1, $2, $3, $4)`, nickname, fullname, about, email)
	defer rows.Close()

	if err != nil {
		return responses.InternalError("Database returned unexpected error: " + err.Error())
	}

	var users []responses.User
	var user responses.User
	for rows.Next() {
		err = rows.Scan(&user.IsNew, &user.Nickname, &user.Fullname, &user.About, &user.Email)
		if err != nil {
			return responses.InternalError("Error while scanning row: " + err.Error())
		}
		code = 201
		response = &user
		users = append(users, user)
	}
	err = rows.Err()
	if err != nil {
		return responses.InternalError("Error returned by rows: " + err.Error())
	}

	if !user.IsNew {
		code = 409
		response = &users
	}
	err = tx.Commit()
	if err != nil {
		return responses.InternalError("Error while committing transaction: " + err.Error())
	}
	return
}

