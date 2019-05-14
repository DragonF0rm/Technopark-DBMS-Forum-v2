package service

import (
	"net/http"
)

func ClearHandler(w http.ResponseWriter, r *http.Request) {
	err := clear()
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		return
	} else {
		w.WriteHeader(http.StatusOK)
		return
	}
}
