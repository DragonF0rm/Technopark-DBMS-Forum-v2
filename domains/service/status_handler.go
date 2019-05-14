package service

import (
	"encoding/json"
	"net/http"
)

func StatusHandler(w http.ResponseWriter, r *http.Request) {
	code, response := status()
	responseJSON, err := json.Marshal(response)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}

	w.WriteHeader(code)
	_, err = w.Write(responseJSON)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}
	return
}
