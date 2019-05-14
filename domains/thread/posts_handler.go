package thread

import (
	"bytes"
	"encoding/json"
	"github.com/gorilla/mux"
	"net/http"
	"strconv"
)

func PostsHandler(w http.ResponseWriter, r *http.Request) {
	limit, err := strconv.Atoi(r.URL.Query().Get("limit"))
	if err != nil {
		limit = 100
	}

	since, err := strconv.Atoi(r.URL.Query().Get("since"))
	if err != nil {
		since = 0
	}

	sort := r.URL.Query().Get("sort")
	if sort == "" {
		sort = "flat"
	}

	desc, err := strconv.ParseBool(r.URL.Query().Get("desc"))
	if err != nil {
		desc = false
	}

	code, response := posts(mux.Vars(r)["slug_or_id"], int32(limit), int64(since), sort, desc)
	responseJSON, err := json.Marshal(response)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}
	if bytes.Equal(responseJSON,[]byte("null")) {
		responseJSON = []byte("[]")
	}

	w.WriteHeader(code)
	_, err = w.Write(responseJSON)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}
	return
}
