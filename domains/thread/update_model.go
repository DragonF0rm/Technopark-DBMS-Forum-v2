package thread

import (
	"github.com/DragonF0rm/Technopark-DBMS-Forum/database"
	"github.com/DragonF0rm/Technopark-DBMS-Forum/responses"
	"strconv"
)

func update(slugOrID string, title, message string)(code int, response interface{}) {
	conn, err := database.GetInstance().ConnPool.Acquire()
	defer database.GetInstance().ConnPool.Release(conn)
	tx, err := conn.Begin()
	if err != nil {
		return responses.InternalError("Error while starting transaction: " + err.Error())
	}
	defer tx.Rollback()

	id, err := strconv.ParseInt(slugOrID, 10, 64)
	if err != nil {
		id, err = getIdBySlug(slugOrID, tx)
		if err != nil {
			switch err.Error() {
			case "ERROR: no_data_found (SQLSTATE P0002)":
				code = 404
				var msg responses.Error
				msg.Message = "Can't find thread"
				response = &msg
				return
			default:
				return responses.InternalError("Database returned unexpected error: " + err.Error())
			}
		}
	}

	row := tx.QueryRow(`SELECT * FROM func_thread_change($1, $2, $3)`, id, title, message)
	var thread responses.Thread
	err = row.Scan(&thread.IsNew, &thread.ID, &thread.Title, &thread.Author, &thread.Forum, &thread.Message, &thread.Votes, &thread.Slug, &thread.Created)
	if err == nil {
		code = 200
		response = &thread
		err = tx.Commit()
		if err != nil {
			return responses.InternalError("Error while committing transaction: " + err.Error())
		}
	} else {
		switch err.Error() {
		case "ERROR: no_data_found (SQLSTATE P0002)":
			code = 404
			var msg responses.Error
			msg.Message = "Can't find thread"
			response = &msg
			return
		default:
			return responses.InternalError("Database returned unexpected error: " + err.Error())
		}
	}
	return
}