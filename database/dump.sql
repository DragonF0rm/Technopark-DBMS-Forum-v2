--
-- PostgreSQL database dump
--

-- Dumped from database version 10.7 (Ubuntu 10.7-0ubuntu0.18.04.1)
-- Dumped by pg_dump version 10.7 (Ubuntu 10.7-0ubuntu0.18.04.1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: Vote; Type: TYPE; Schema: public; Owner: maxim
--

CREATE TYPE public."Vote" AS ENUM (
    '-1',
    '1'
);


ALTER TYPE public."Vote" OWNER TO maxim;

--
-- Name: type_forum; Type: TYPE; Schema: public; Owner: maxim
--

CREATE TYPE public.type_forum AS (
	title character varying,
	"user" character varying,
	slug character varying,
	posts bigint,
	threads integer,
	is_new boolean
);


ALTER TYPE public.type_forum OWNER TO maxim;

--
-- Name: type_post; Type: TYPE; Schema: public; Owner: maxim
--

CREATE TYPE public.type_post AS (
	id bigint,
	parent bigint,
	author character varying,
	message character varying,
	"isEdited" boolean,
	forum character varying,
	thread bigint,
	created timestamp with time zone,
	is_new boolean
);


ALTER TYPE public.type_post OWNER TO maxim;

--
-- Name: type_post_data; Type: TYPE; Schema: public; Owner: maxim
--

CREATE TYPE public.type_post_data AS (
	parent bigint,
	author character varying,
	message character varying
);


ALTER TYPE public.type_post_data OWNER TO maxim;

--
-- Name: type_status; Type: TYPE; Schema: public; Owner: maxim
--

CREATE TYPE public.type_status AS (
	"user" integer,
	forum integer,
	thread integer,
	post integer
);


ALTER TYPE public.type_status OWNER TO maxim;

--
-- Name: type_thread; Type: TYPE; Schema: public; Owner: maxim
--

CREATE TYPE public.type_thread AS (
	is_new boolean,
	id bigint,
	title character varying(256),
	author character varying,
	forum character varying,
	message character varying,
	votes integer,
	slug character varying,
	created timestamp with time zone
);


ALTER TYPE public.type_thread OWNER TO maxim;

--
-- Name: type_user; Type: TYPE; Schema: public; Owner: maxim
--

CREATE TYPE public.type_user AS (
	is_new boolean,
	nickname character varying,
	fullname character varying,
	about character varying,
	email character varying
);


ALTER TYPE public.type_user OWNER TO maxim;

--
-- Name: func_add_post_to_forum(); Type: FUNCTION; Schema: public; Owner: maxim
--

CREATE FUNCTION public.func_add_post_to_forum() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    user_forums BIGINT[];
BEGIN
    UPDATE "Forums" SET posts = posts + 1 WHERE id = NEW."forum-id";
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.func_add_post_to_forum() OWNER TO maxim;

--
-- Name: func_add_thread_to_forum(); Type: FUNCTION; Schema: public; Owner: maxim
--

CREATE FUNCTION public.func_add_thread_to_forum() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
BEGIN
    UPDATE "Forums" SET threads = threads + 1 WHERE id = NEW."forum-id";
    UPDATE "Users"
    SET "writing-to-forum" = CASE
        WHEN "writing-to-forum" @> ('{}'::bigint[] || NEW."forum-id")
            THEN "writing-to-forum"
        ELSE "writing-to-forum" || NEW."forum-id"
    END
    WHERE id = NEW."author-id";
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.func_add_thread_to_forum() OWNER TO maxim;

--
-- Name: func_add_vote_to_thread(); Type: FUNCTION; Schema: public; Owner: maxim
--

CREATE FUNCTION public.func_add_vote_to_thread() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    voice int;
BEGIN
    voice := NEW.voice;
    UPDATE "Threads" SET votes = votes + voice WHERE id = NEW."thread-id";
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.func_add_vote_to_thread() OWNER TO maxim;

--
-- Name: func_check_post_before_adding(); Type: FUNCTION; Schema: public; Owner: maxim
--

CREATE FUNCTION public.func_check_post_before_adding() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    parent RECORD;
    thread RECORD;
BEGIN
    IF  NEW."parent-id" IS NOT NULL
    AND NEW."parent-id" != 0 THEN
        SELECT * INTO parent
        from "Posts"
        WHERE id = NEW."parent-id";
    
        SELECT * into thread
        FROM "Threads"
        WHERE id = NEW."thread-id";
    
        if NEW."forum-id" != parent."forum-id"
        OR NEW."thread-id" != parent."thread-id"
        OR NEW."forum-id" != thread."forum-id"
        THEN
            RAISE integrity_constraint_violation;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.func_check_post_before_adding() OWNER TO maxim;

--
-- Name: func_convert_post_parent_zero_into_null(); Type: FUNCTION; Schema: public; Owner: maxim
--

CREATE FUNCTION public.func_convert_post_parent_zero_into_null() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
BEGIN
    IF NEW."parent-id" = 0 THEN
       NEW."parent-id" := NULL;
    END IF;
    RETURN NEW;
END; 
$$;


ALTER FUNCTION public.func_convert_post_parent_zero_into_null() OWNER TO maxim;

--
-- Name: func_convert_post_parent_zero_into_null$$(); Type: FUNCTION; Schema: public; Owner: maxim
--

CREATE FUNCTION public."func_convert_post_parent_zero_into_null$$"() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
BEGIN
    IF NEW."parent-id" = 0 THEN
       NEW."parent-id" := NULL;
    END IF;
    RETURN NEW;
END; 
$$;


ALTER FUNCTION public."func_convert_post_parent_zero_into_null$$"() OWNER TO maxim;

--
-- Name: func_delete_post_from_forum(); Type: FUNCTION; Schema: public; Owner: maxim
--

CREATE FUNCTION public.func_delete_post_from_forum() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
BEGIN
  	UPDATE "Forums" SET posts = posts -1 WHERE id = OLD."forum-id";
  	RETURN NEW;
END;
$$;


ALTER FUNCTION public.func_delete_post_from_forum() OWNER TO maxim;

--
-- Name: func_delete_thread_from_forum(); Type: FUNCTION; Schema: public; Owner: maxim
--

CREATE FUNCTION public.func_delete_thread_from_forum() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
BEGIN
    UPDATE "Forums" SET threads = threads - 1 WHERE id = OLD."forum-id";
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.func_delete_thread_from_forum() OWNER TO maxim;

--
-- Name: func_delete_vote_from_thread(); Type: FUNCTION; Schema: public; Owner: maxim
--

CREATE FUNCTION public.func_delete_vote_from_thread() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    voice int;
BEGIN
    voice := OLD.voice;
    UPDATE "Threads" SET votes = votes - voice WHERE id = OLD."thread-id";
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.func_delete_vote_from_thread() OWNER TO maxim;

--
-- Name: func_edit_post(); Type: FUNCTION; Schema: public; Owner: maxim
--

CREATE FUNCTION public.func_edit_post() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
BEGIN
    if OLD.message != NEW.message THEN
        NEW."is-edited" = TRUE;
    END IF;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.func_edit_post() OWNER TO maxim;

--
-- Name: func_forum_create(character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: maxim
--

CREATE FUNCTION public.func_forum_create(arg_title character varying, arg_nickname character varying, arg_slug character varying) RETURNS TABLE(res_is_new boolean, res_title character varying, res_user character varying, res_slug character varying, res_posts bigint, res_threads bigint)
    LANGUAGE plpgsql
    AS $$
DECLARE
    user_id BIGINT;
BEGIN
    SELECT id, nickname into user_id, res_user
    from "Users"
    WHERE lower(nickname) = lower(arg_nickname);
    IF not found then
        RAISe no_data_found;
    end if;
    begin
        res_is_new := true;
        INSERT into "Forums"(title, "user-id", slug)
        VALUES (arg_title, user_id, arg_slug)
        RETURNING title, slug, posts, threads
        into res_title, res_slug, res_posts, res_threads;
        RETURN NEXT;
    EXCEPTION
        WHEN unique_violation THEN
            begin
                res_is_new := false;
                select f.title, f.slug, f.posts, f.threads
                into res_title, res_slug, res_posts, res_threads
                FROM "Forums" f
                where lower(f.slug) = lower(arg_slug);
                return NEXT;
            end;
    END;
END;
$$;


ALTER FUNCTION public.func_forum_create(arg_title character varying, arg_nickname character varying, arg_slug character varying) OWNER TO maxim;

--
-- Name: func_forum_create_thread(character varying, character varying, character varying, character varying, character varying, timestamp with time zone); Type: FUNCTION; Schema: public; Owner: maxim
--

CREATE FUNCTION public.func_forum_create_thread(arg_forum_slug character varying, arg_thread_slug character varying, arg_title character varying, arg_author character varying, arg_message character varying, arg_created timestamp with time zone) RETURNS public.type_thread
    LANGUAGE plpgsql
    AS $$
DECLARE
    result type_thread;
    user_id BIGINT;
    forum_id BIGINT;
BEGIN
    select id INTO user_id
    FROM "Users"
    WHERE lower(nickname) = lower(arg_author);
    IF not found then
        RAISe no_data_found;
    end if;
    result.author := arg_author;
    
    SELECT f.id, f.slug INTO forum_id, result.forum
    FROM "Forums" f
    WHERE lower(f.slug) = lower(arg_forum_slug);
    if not found then
        RAISe no_data_found;
    end if;
    
    begin
        result.is_new := true;
        INSERT INTO "Threads" ("author-id", created, "forum-id", message, slug, title)
        VALUES (user_id, arg_created, forum_id, arg_message,arg_thread_slug, arg_title)
        RETURNING id, title, message, votes, slug, created
        INTO result.id, result.title, result.message, result.votes, result.slug, result.created;
        RETURN result;
    EXCEPTION
        WHEN unique_violation THEN
            begin
                result.is_new := false;
                SELECT t.id, t.title, u.nickname, f.slug, t.message, t.votes, t.slug, t.created
                INTO result.id, result.title, result.author, result.forum, result.message, result.votes, result.slug, result.created
                FROM "Threads" t
                JOIN "Users" u ON u.id = t."author-id"
                JOIN "Forums" f ON f.id = t."forum-id"
                WHERE lower(t.slug) = lower(arg_thread_slug);
                return result;
            end;
    end;
END;
$$;


ALTER FUNCTION public.func_forum_create_thread(arg_forum_slug character varying, arg_thread_slug character varying, arg_title character varying, arg_author character varying, arg_message character varying, arg_created timestamp with time zone) OWNER TO maxim;

--
-- Name: func_forum_details(character varying); Type: FUNCTION; Schema: public; Owner: maxim
--

CREATE FUNCTION public.func_forum_details(arg_slug character varying) RETURNS public.type_forum
    LANGUAGE plpgsql
    AS $$
DECLARE
    result type_forum;
BEGIN
    result.is_new := FALSE;
    SELECT f.title, u.nickname, f.slug, f.posts, f.threads
    INTO result.title, result.user, result.slug, result.posts, result.threads
    FROM "Forums" f
    JOIN "Users" u ON u.id = f."user-id"
    WHERE lower(f.slug) = lower(arg_slug);
    if not found then
        RAISe no_data_found;
    end if;
    RETURN result;
END;
$$;


ALTER FUNCTION public.func_forum_details(arg_slug character varying) OWNER TO maxim;

--
-- Name: func_forum_threads(character varying, timestamp with time zone, boolean, integer); Type: FUNCTION; Schema: public; Owner: maxim
--

CREATE FUNCTION public.func_forum_threads(arg_slug character varying, arg_since timestamp with time zone, arg_desc boolean, arg_limit integer DEFAULT 100) RETURNS SETOF public.type_thread
    LANGUAGE plpgsql
    AS $$
DECLARE
    forum_id BIGINT;
    result type_thread;
    rec RECORD;
BEGIN
    result.is_new := false;
    
    SELECT id, slug into forum_id, result.forum
    from "Forums"
    where lower(slug) = lower(arg_slug);
    if not found then
        RAISe no_data_found;
    end if;
    
    FOR rec in SELECT t.id, t.title, u.nickname, t.message, t.votes, t.slug, t.created
        FROM "Threads" t 
        JOIN "Users" u on u.id = t."author-id"
        WHERE t."forum-id" = forum_id
        and CASE
            when arg_since is null then true
            WHEN arg_desc THEN t.created <= arg_since
            ELSE t.created >= arg_since
        END
        ORDER BY
            (case WHEN arg_desc THEN t.created END) DESC,
            (CASE WHEN not arg_desc THEN t.created END) ASC
        LIMIT arg_limit
    LOOp
        result.id := rec.id;
        result.title := rec.title;
        result.author := rec.nickname;
        result.message := rec.message;
        result.votes := rec.votes;
        result.slug := rec.slug;
        result.created := rec.created;
        RETURN next result;
    end loop;
END;
$$;


ALTER FUNCTION public.func_forum_threads(arg_slug character varying, arg_since timestamp with time zone, arg_desc boolean, arg_limit integer) OWNER TO maxim;

--
-- Name: func_forum_users(character varying, character varying, boolean, integer); Type: FUNCTION; Schema: public; Owner: maxim
--

CREATE FUNCTION public.func_forum_users(arg_slug character varying, arg_since character varying, arg_desc boolean, arg_limit integer DEFAULT 100) RETURNS SETOF public.type_user
    LANGUAGE plpgsql
    AS $$
DECLARE
    forum_id BIGINT;
    result type_user;
    rec RECORD;
BEGIN
    result.is_new := false;
    
    SELECT id into forum_id
    from "Forums"
    where lower(slug) = lower(arg_slug);
    if not found then
        RAISe no_data_found;
    end if;
    
    FOR rec in SELECT u.nickname, u.fullname, u.about, u.email
        FROM "Users" u
        WHERE "writing-to-forum" @> ('{}'::bigint[] || forum_id)
        AND CASE
            when arg_since is null then true
            WHEN arg_desc THEN lower(u.nickname)::bytea < lower(arg_since)::bytea
            ELSE lower(u.nickname)::bytea > lower(arg_since)::bytea
        END
        ORDER BY
            (case WHEN arg_desc THEN lower(u.nickname)::bytea END) DESC,
            (CASE WHEN not arg_desc THEN lower(u.nickname)::bytea END) ASC
        LIMIT arg_limit
    LOOp
        result.nickname := rec.nickname;
        result.fullname := rec.fullname;
        result.about := rec.about;
        result.email := rec.email;
        RETURN next result;
    end loop;
END;
$$;


ALTER FUNCTION public.func_forum_users(arg_slug character varying, arg_since character varying, arg_desc boolean, arg_limit integer) OWNER TO maxim;

--
-- Name: func_make_path_for_post(); Type: FUNCTION; Schema: public; Owner: maxim
--

CREATE FUNCTION public.func_make_path_for_post() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    parent RECORD;
BEGIN
    IF  NEW."parent-id" IS NOT NULL
    AND NEW."parent-id" != 0
    THEN
        SELECT * INTO parent
        FROM "Posts"
        WHERE id = NEW."parent-id";
        NEW.path := parent.path || parent.id;
    END IF;
    RETURN NEW; 
END;
$$;


ALTER FUNCTION public.func_make_path_for_post() OWNER TO maxim;

--
-- Name: func_post_change(bigint, character varying); Type: FUNCTION; Schema: public; Owner: maxim
--

CREATE FUNCTION public.func_post_change(arg_id bigint, arg_post character varying) RETURNS public.type_post
    LANGUAGE plpgsql
    AS $$
DECLARE
    author_id BIGINT;
    forum_id BIGINT;
    result type_post;
BEGIN
    result.is_new := FALSE;
    UPDATE "Posts"
    SET message = CASE
        WHEN arg_post != '' THEN arg_post
        ELSE message END
    WHERE id = arg_id
    REturning id, "parent-id", "author-id", message, "is-edited", "forum-id", "thread-id", created
    INTO result.id, result.parent, author_id, result.message, result."isEdited", forum_id, result.thread, result.created;
    if not found then
        RAISe no_data_found;
    end if;
    
    SELECT nickname INTo result.author FROM "Users" where id = author_id;
    if not found then
        RAISe no_data_found;
    end if;
    
    SELECT slug InTO result.forum FROM "Forums" Where id = forum_id;
    if not found then
        RAISe no_data_found;
    end if;
    
    if result.parent is null then
        result.parent = 0;
    end if;
    
    return result;
END;
$$;


ALTER FUNCTION public.func_post_change(arg_id bigint, arg_post character varying) OWNER TO maxim;

--
-- Name: func_post_details(bigint); Type: FUNCTION; Schema: public; Owner: maxim
--

CREATE FUNCTION public.func_post_details(arg_id bigint) RETURNS public.type_post
    LANGUAGE plpgsql
    AS $$
DECLARE
    result type_post;
BEGIN
    result.is_new := false;
    SELECT p.id, p."parent-id", u.nickname, p.message, p."is-edited", f.slug, p."thread-id", p.created
    INTO result.id, result.parent, result.author, result.message, result."isEdited", result.forum, result.thread, result.created
    FROM "Posts" p
    JOIN "Users" u on u.id = p."author-id"
    JOIN "Forums" f ON f.id = p."forum-id"
    WHERE p.id = arg_id;
    if not found then
        RAISe no_data_found;
    end if;
    IF result.parent IS NULL THEN
        result.parent := 0;
    END IF;
    RETURN result;
END;
$$;


ALTER FUNCTION public.func_post_details(arg_id bigint) OWNER TO maxim;

--
-- Name: func_service_clear(); Type: FUNCTION; Schema: public; Owner: maxim
--

CREATE FUNCTION public.func_service_clear() RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
BEGIN
    TRUNCATE TABLE "Users", "Forums", "Threads", "Posts", "Votes";
END;
$$;


ALTER FUNCTION public.func_service_clear() OWNER TO maxim;

--
-- Name: func_service_status(); Type: FUNCTION; Schema: public; Owner: maxim
--

CREATE FUNCTION public.func_service_status() RETURNS public.type_status
    LANGUAGE plpgsql
    AS $$
DECLARE
    result type_status;
BEGIN
    SELECT count(*) INTO result.user FROM (
        SELECT * FROM "Users"
    ) u;
    SELECT count(*) INTO result.forum FROM (
        SELECT * FROM "Forums" f
    ) f;
    SELECT count(*) INTO result.thread FROM (
        SELECT * FROM "Threads"
    ) t;
    SELECT count(*) INTO result.post FROM (
        SELECT * FROM "Posts"
    ) p;
    RETURN result;
END;
$$;


ALTER FUNCTION public.func_service_status() OWNER TO maxim;

--
-- Name: func_thread_change(bigint, character varying, character varying); Type: FUNCTION; Schema: public; Owner: maxim
--

CREATE FUNCTION public.func_thread_change(arg_id bigint, arg_title character varying, arg_message character varying) RETURNS public.type_thread
    LANGUAGE plpgsql
    AS $$
DECLARE
    result type_thread;
    user_id BIGINT;
    forum_id BIGINT;
BEGIN
    result.is_new := FALSE;
    UPDATE "Threads"
    SET title = CASE
            WHEN arg_title != '' THEN arg_title
            ELSE title END,
        message = CASE
            WHEN arg_message != '' THEN arg_message
            ELSE message END
    Where id = arg_id
    RETURNING id, title, "author-id", message, votes, slug, created, "forum-id"
    INTO result.id, result.title, user_id, result.message, result.votes, result.slug, result.created, forum_id;
    if not found then
        RAISe no_data_found;
    end if;
    SELECT nickname into result.author From "Users" WHERE id = user_id for update;
    if not found then
        RAISe no_data_found;
    end if;
    SELECT slug into result.forum From "Forums" WHERE id = forum_id for update;
    if not found then
        RAISe no_data_found;
    end if;
    return result;
END;
$$;


ALTER FUNCTION public.func_thread_change(arg_id bigint, arg_title character varying, arg_message character varying) OWNER TO maxim;

--
-- Name: func_thread_create_posts(bigint, bigint[], character varying[], character varying[]); Type: FUNCTION; Schema: public; Owner: maxim
--

CREATE FUNCTION public.func_thread_create_posts(arg_id bigint, arg_parents bigint[], arg_authors character varying[], arg_messages character varying[]) RETURNS SETOF public.type_post
    LANGUAGE plpgsql
    AS $$
DECLARE
    result type_post;
    user_id BIGINT;
    forum_id BIGINT;
    array_length INTEGER;
    i Integer;
    post type_post_data;
    author_nickname character varying;
BEGIN
    array_length := array_length(arg_parents, 1);
    IF array_length != array_length(arg_authors, 1)
    OR array_length != array_length(arg_messages, 1)
    THEN
        RAISE invalid_parameter_value;
    END IF;
    
    result.is_new := false;
    result.created := now(); 
    
    SELECT t."forum-id", f.slug INTO forum_id, result.forum
    FROM "Threads" t
    JOIN "Forums" f ON f.id = t."forum-id"
    WHERE t.id = arg_id;
    if not found then
        RAISe no_data_found;
    end if;
    result.thread := arg_id;
    
    IF array_length is null then
        RETURN;
    END IF;
    
    i := 1;
    
    LOOP
        EXIT WHEN i > array_length;
        
        post.parent  := arg_parents[i];
        IF post.parent = 0 THEN
            post.parent := NULL;
        END IF;
        post.author  := arg_authors[i];
        post.message := arg_messages[i];
        
        if post.parent is null then
            result.parent = 0;
        else
            result.parent := post.parent;
        end if;   
    
        SELECT id into user_id
        from "Users"
        WHERE lower(nickname) = lower(post.author);
        if not found then
            RAISe no_data_found;
        end if;
        result.author := post.author;
        
        INSERT into "Posts"("author-id", created, "forum-id", message, "parent-id", "thread-id")
        VALUES (user_id, result.created, forum_id, post.message, post.parent, arg_id)
        RETURNING  id, message, "is-edited"
        INTO result.id, result.message, result."isEdited";
        
        RETURN NEXT result;
        
        i := i + 1;
    END LOOP;
   
    UPDATE "Users"
    SET "writing-to-forum" = CASE
        WHEN "writing-to-forum" @> ('{}'::bigint[] || forum_id)
            THEN "writing-to-forum"
        ELSE "writing-to-forum" || forum_id
    END
    WHERE lower(nickname) IN
        (SELECT DISTINCT lower(nickname) FROM unnest(arg_authors) AS nickname)
    AND lower(nickname) NOT IN
        (SELECT DISTINCT lower(nickname) FROM "Users" WHERE "writing-to-forum" @> ('{}'::bigint[] || forum_id));
EXCEPTION
    WHEN unique_violation THEN
        RAISE unique_violation;
    WHEN integrity_constraint_violation THEN
        RAISE integrity_constraint_violation;
END;
$$;


ALTER FUNCTION public.func_thread_create_posts(arg_id bigint, arg_parents bigint[], arg_authors character varying[], arg_messages character varying[]) OWNER TO maxim;

--
-- Name: func_thread_details(bigint); Type: FUNCTION; Schema: public; Owner: maxim
--

CREATE FUNCTION public.func_thread_details(arg_id bigint) RETURNS public.type_thread
    LANGUAGE plpgsql
    AS $$
DECLARE
    result type_thread;
BEGIN
    result.is_new := false;
    SELECT t.id, t.title, u.nickname, f.slug, t.message, t.votes, t.slug, t.created
    into result.id, result.title, result.author, result.forum, result.message, result.votes, result.slug, result.created
    from "Threads" t
    JOIN "Users" u ON u.id = t."author-id"
    JOIN "Forums" f ON f.id = t."forum-id"
    WHERE t.id = arg_id;
    if not found then
        RAISe no_data_found;
    end if;
    return result;
END;
$$;


ALTER FUNCTION public.func_thread_details(arg_id bigint) OWNER TO maxim;

--
-- Name: func_thread_get_id_by_slug(character varying); Type: FUNCTION; Schema: public; Owner: maxim
--

CREATE FUNCTION public.func_thread_get_id_by_slug(arg_slug character varying) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE
    result BIGINT;
BEGIN
    SELECT id into result
    from "Threads"
    where lower(slug) = lower(arg_slug);
    if not found then
        RAISe no_data_found;
    end if;
    return result;
END;
$$;


ALTER FUNCTION public.func_thread_get_id_by_slug(arg_slug character varying) OWNER TO maxim;

--
-- Name: func_thread_get_post_layer(bigint, bigint, bigint, boolean, integer); Type: FUNCTION; Schema: public; Owner: maxim
--

CREATE FUNCTION public.func_thread_get_post_layer(arg_thread_id bigint, arg_parent_id bigint, arg_since_id bigint, arg_desc boolean, arg_limit integer DEFAULT NULL::integer) RETURNS SETOF public.type_post
    LANGUAGE plpgsql
    AS $$
DECLARE
    result type_post;
    rec RECORD;
BEGIN
    result.is_new := false;
    FOR rec in SELECT p.id, p."parent-id", u.nickname, p.message, p."is-edited", f.slug, p."thread-id", p.created
        FROM "Posts" p 
        JOIN "Users" u on u.id = p."author-id"
        JOIN "Forums" f ON f.id = p."forum-id"
        WHERE p."thread-id" = arg_thread_id
        and case
            WHEN arg_parent_id = 0 THEN p."parent-id" IS NULL
            ELSE p."parent-id" = arg_parent_id
        END
        and CASE
            when arg_since_id is null then true
            WHEN arg_desc THEN p.id < arg_since_id
            ELSE p.id > arg_since_id
        END
        ORDER BY
            (case WHEN arg_desc THEN p.created END) DESC,
            (CASE WHEN not arg_desc THEN p.created END) ASC
        LIMIT arg_limit
    LOOp
        result.id := rec.id;
         IF rec."parent-id" is null then
            result.parent := 0;
        ELSE
            result.parent := rec."parent-id";
        end if;
        result.author := rec.nickname;
        result.message := rec.message;
        result."isEdited" := rec."is-edited";
        result.forum := rec.slug;
        result.thread := rec."thread-id";
        result.created := rec.created;
        RETURN next result;
    end loop;
END;
$$;


ALTER FUNCTION public.func_thread_get_post_layer(arg_thread_id bigint, arg_parent_id bigint, arg_since_id bigint, arg_desc boolean, arg_limit integer) OWNER TO maxim;

--
-- Name: func_thread_posts_flat(bigint, bigint, boolean, integer); Type: FUNCTION; Schema: public; Owner: maxim
--

CREATE FUNCTION public.func_thread_posts_flat(arg_thread_id bigint, arg_since_id bigint, arg_desc boolean, arg_limit integer DEFAULT 100) RETURNS SETOF public.type_post
    LANGUAGE plpgsql
    AS $$
DECLARE
    result type_post;
    rec RECORD;
BEGIN
    result.is_new := false;
    SELECT *
    Into rec
    from "Threads"
    where id = arg_thread_id;
    if not found then
        RAISe no_data_found;
    end if;
    
    FOR rec iN SELECT p.id, p."parent-id", u.nickname, p.message, p."is-edited", f.slug, p."thread-id", p.created
        FROM "Posts" p
        JOIN "Users" u on u.id = p."author-id"
        JOIN "Forums" f ON f.id = p."forum-id"
        WHERE p."thread-id" = arg_thread_id
        AND CASE
            when arg_since_id is null OR arg_since_id = 0 then true
           ELSE CASE
                WHEN arg_desc THEN p.id < arg_since_id
                ELSE p.id > arg_since_id
            END
        END
        ORDER BY
            (case WHEN arg_desc THEN p.id END) DESC,
            (CASE WHEN not arg_desc THEN p.id END) ASC
        LIMIT arg_limit
    LOOp
        result.id := rec.id;
        IF rec."parent-id" is null then
            result.parent := 0;
        ELSE
            result.parent := rec."parent-id";
        end if;
        result.author := rec.nickname;
        result.message := rec.message;
        result."isEdited" := rec."is-edited";
        result.forum := rec.slug;
        result.thread := rec."thread-id";
        result.created := rec.created;
        RETURN next result;
    end loop;
END;
$$;


ALTER FUNCTION public.func_thread_posts_flat(arg_thread_id bigint, arg_since_id bigint, arg_desc boolean, arg_limit integer) OWNER TO maxim;

--
-- Name: func_thread_posts_parent_tree(bigint, bigint, boolean, integer); Type: FUNCTION; Schema: public; Owner: maxim
--

CREATE FUNCTION public.func_thread_posts_parent_tree(arg_thread_id bigint, arg_since_id bigint, arg_desc boolean, arg_limit integer DEFAULT 100) RETURNS SETOF public.type_post
    LANGUAGE plpgsql
    AS $$
DECLARE
    result type_post;
    rec RECORD;
    root RECORD;
    since_root_id BIGINT;
    depth INTEGER;
BEGIN
    result.is_new := false;

    SELECT *
    Into rec
    from "Threads"
    where id = arg_thread_id;
    if not found then
        RAISe no_data_found;
    end if;

    SELECT (path || id)[2], array_length(path, 1) + 1
    INTO since_root_id, depth
    FROM "Posts"
    WHERE id = arg_since_id;
    
    FOR rec IN
        SELECT p.id, p."parent-id", u.nickname, p.message, p."is-edited", f.slug, p."thread-id", p.created
        FROM "Posts" p
        JOIN "Users" u on u.id = p."author-id"
        JOIN "Forums" f ON f.id = p."forum-id"
        WHERE p."thread-id" = arg_thread_id
        AND (p.path || p.id)[2] IN (
            SELECT inner_p.id
            FROM "Posts" inner_p
            WHERE inner_p."parent-id" IS NULL
            AND inner_p."thread-id" = arg_thread_id
            AND CASE
                when since_root_id IS NULL then true
                ELSE CASE
                    WHEN arg_desc THEN inner_p.id < since_root_id
                    ELSE inner_p.id > since_root_id
                END
            END
            ORDER BY
                (case WHEN arg_desc THEN inner_p.id END) DESC,
                (CASE WHEN not arg_desc THEN inner_p.id END) ASC
            LIMIT arg_limit
        )
        --AND CASE
        --    when since_root_id is null then true
        --    ELSE (p.path || p.id)[2] = since_root_id
        --END
        ORDER BY
            (case WHEN arg_desc THEN (p.path || p.id)[2] END) DESC,
            (CASE WHEN not arg_desc THEN (p.path || p.id)[2] END) ASC,
            p.path || p.id
    LOOP
        result.id := rec.id;
        IF rec."parent-id" is null then
            result.parent := 0;
        ELSE
            result.parent := rec."parent-id";
        end if;
        result.author := rec.nickname;
        result.message := rec.message;
        result."isEdited" := rec."is-edited";
        result.forum := rec.slug;
        result.thread := rec."thread-id";
        result.created := rec.created;
        RETURN next result;
    END LOOP;
END;
$$;


ALTER FUNCTION public.func_thread_posts_parent_tree(arg_thread_id bigint, arg_since_id bigint, arg_desc boolean, arg_limit integer) OWNER TO maxim;

--
-- Name: func_thread_posts_tree(bigint, bigint, boolean, integer); Type: FUNCTION; Schema: public; Owner: maxim
--

CREATE FUNCTION public.func_thread_posts_tree(arg_thread_id bigint, arg_since_id bigint, arg_desc boolean, arg_limit integer DEFAULT 100) RETURNS SETOF public.type_post
    LANGUAGE plpgsql
    AS $$
DECLARE
    result type_post;
    rec RECORD;
    since_path BIGINT[];
BEGIN
    result.is_new := false;
    
    SELECT *
    Into rec
    from "Threads"
    where id = arg_thread_id;
    if not found then
        RAISe no_data_found;
    end if;
    
    IF arg_since_id = 0 THEN
        arg_since_id = NULL;
    END IF;
    
    IF arg_since_id IS NOT NULL THEN
        SELECT (path || id) INTO since_path
        FROM "Posts"
        WHERE id = arg_since_id;
        IF not found THEN
            RAISE no_data_found;
        END IF;
    END IF;
    
    FOR rec IN
        SELECT p.id, p."parent-id", u.nickname, p.message, p."is-edited", f.slug, p."thread-id", p.created
        FROM "Posts" p
        JOIN "Users" u on u.id = p."author-id"
        JOIN "Forums" f ON f.id = p."forum-id"
        WHERE p."thread-id" = arg_thread_id
        AND CASE
            when arg_since_id is null then true
            ELSE CASE
                WHEN arg_desc then (p.path || p.id) < since_path
                ELSE (p.path || p.id) > since_path
            END
        END
        ORDER BY
            (case WHEN arg_desc THEN p.path || p.id END) DESC,
            (CASE WHEN not arg_desc THEN p.path || p.id END) ASC,
            p.id
        LIMIT arg_limit
    LOOP
        result.id := rec.id;
        IF rec."parent-id" is null then
            result.parent := 0;
        ELSE
            result.parent := rec."parent-id";
        end if;
        result.author := rec.nickname;
        result.message := rec.message;
        result."isEdited" := rec."is-edited";
        result.forum := rec.slug;
        result.thread := rec."thread-id";
        result.created := rec.created;
        RETURN next result;
    END LOOP;
END;
$$;


ALTER FUNCTION public.func_thread_posts_tree(arg_thread_id bigint, arg_since_id bigint, arg_desc boolean, arg_limit integer) OWNER TO maxim;

--
-- Name: func_thread_posts_tree_from_root(bigint, bigint, boolean, integer); Type: FUNCTION; Schema: public; Owner: maxim
--

CREATE FUNCTION public.func_thread_posts_tree_from_root(arg_thread_id bigint, arg_since_id bigint, arg_desc boolean, arg_limit integer DEFAULT 100) RETURNS SETOF public.type_post
    LANGUAGE plpgsql
    AS $$
DECLARE
    result type_post;
    rec RECORD;
    depth INTEGER;
BEGIN
    result.is_new := false;
    
    IF arg_since_id = 0 THEN
        arg_since_id = NULL;
    END IF;
    
    IF arg_since_id IS NULL THEN
        depth := 1;
    ELSE
        SELECT array_length(path, 1) + 1 INTO depth
        FROM "Posts"
        WHERE id = arg_since_id;
        IF not found THEN
            RAISE no_data_found;
        END IF;
    END IF;
    
    FOR rec IN
        SELECT p.id, p."parent-id", u.nickname, p.message, p."is-edited", f.slug, p."thread-id", p.created
        FROM "Posts" p
        JOIN "Users" u on u.id = p."author-id"
        JOIN "Forums" f ON f.id = p."forum-id"
        WHERE p."thread-id" = arg_thread_id
        AND CASE
            when arg_since_id is null then true
            ELSE (p.path || p.id)[depth] = arg_since_id
        END
        ORDER BY
            p.path || p.id,
            (case WHEN arg_desc THEN p.id END) DESC,
            (CASE WHEN not arg_desc THEN p.id END) ASC
        LIMIT arg_limit
    LOOP
        result.id := rec.id;
        IF rec."parent-id" is null then
            result.parent := 0;
        ELSE
            result.parent := rec."parent-id";
        end if;
        result.author := rec.nickname;
        result.message := rec.message;
        result."isEdited" := rec."is-edited";
        result.forum := rec.slug;
        result.thread := rec."thread-id";
        result.created := rec.created;
        RETURN next result;
    END LOOP;
END;
$$;


ALTER FUNCTION public.func_thread_posts_tree_from_root(arg_thread_id bigint, arg_since_id bigint, arg_desc boolean, arg_limit integer) OWNER TO maxim;

--
-- Name: func_thread_vote(bigint, character varying, boolean); Type: FUNCTION; Schema: public; Owner: maxim
--

CREATE FUNCTION public.func_thread_vote(arg_id bigint, arg_nickname character varying, arg_like boolean) RETURNS public.type_thread
    LANGUAGE plpgsql
    AS $$
DECLARE
    voice_val "public"."Vote";
    user_id BIGINT;
    result type_thread;
BEGIN
    result.is_new := false;
    if arg_like then
        voice_val := 1;
    else
        voice_val := -1;
    END IF;
    SELECT id into user_id
    from "Users"
    WHERE lower(nickname) = lower(arg_nickname);
    IF NOT FOUND THEN
        RAISE no_data_found;
    END IF;
    INSERT into "Votes"("user-id", "thread-id", voice) VALUES (user_id, arg_id, voice_val);
    SELECT t.id, t.title, u.nickname, f.slug, t.message, t.votes, t.slug, t.created
    Into result.id, result.title, result.author, result.forum, result.message, result.votes, result.slug, result.created
    FROM "Threads" t 
    JOIN "Users" u on u.id = t."author-id"
    JOIN "Forums" f ON f.id = t."forum-id"
    WHERE t.id = arg_id;
    return result;
exception
    when unique_violation then
        UPDATE "Votes"
        SET voice = voice_val
        WHERE "user-id" = user_id
        AND "thread-id" = arg_id;
        SELECT t.id, t.title, u.nickname, f.slug, t.message, t.votes, t.slug, t.created
        Into result.id, result.title, result.author, result.forum, result.message, result.votes, result.slug, result.created
        FROM "Threads" t 
        JOIN "Users" u on u.id = t."author-id"
        JOIN "Forums" f ON f.id = t."forum-id"
        WHERE t.id = arg_id;
        return result;
    WHEN foreign_key_violation THEN
        RAISE no_data_found;
END;
$$;


ALTER FUNCTION public.func_thread_vote(arg_id bigint, arg_nickname character varying, arg_like boolean) OWNER TO maxim;

--
-- Name: func_update_vote(); Type: FUNCTION; Schema: public; Owner: maxim
--

CREATE FUNCTION public.func_update_vote() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    voice int;
BEGIN
    if (OLD.voice != NEW.voice)
    then
        voice := NEW.voice;
        voice := 2 * voice;
        UPDATE "Threads" SET votes = votes + voice WHERE id = NEW."thread-id";
    end if;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.func_update_vote() OWNER TO maxim;

--
-- Name: func_user_change_profile(character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: maxim
--

CREATE FUNCTION public.func_user_change_profile(arg_nickname character varying, arg_fullname character varying, arg_about character varying, arg_email character varying) RETURNS public.type_user
    LANGUAGE plpgsql
    AS $$
DECLARE
    result type_user;
    user_id BIGINT;
BEGIN
    result.is_new := FALSE;
    SELECT id INTO user_id
    FROM "Users"
    Where lower(nickname) = lower(arg_nickname);
    if not found then
        RAISe no_data_found;
    end if;
    
    UPDATE "Users"
    SET fullname = CASE
            WHEN arg_fullname != '' THEN arg_fullname
            ELSE fullname END,
        about = CASE
            WHEN arg_about != '' THEN arg_about
            ELSE about END,
        email = CASE
            WHEN arg_email != '' THEN arg_email
            ELSE email END
    Where id = user_id
    RETURNING nickname, fullname, about, email
    INTO result.nickname, result.fullname, result.about, result.email;
    return result;
exception
    when unique_violation THEN
        raise unique_violation;
END;
$$;


ALTER FUNCTION public.func_user_change_profile(arg_nickname character varying, arg_fullname character varying, arg_about character varying, arg_email character varying) OWNER TO maxim;

--
-- Name: func_user_create(character varying, character varying, character varying, character varying); Type: FUNCTION; Schema: public; Owner: maxim
--

CREATE FUNCTION public.func_user_create(arg_nickname character varying, arg_fullname character varying, arg_about character varying, arg_email character varying) RETURNS SETOF public.type_user
    LANGUAGE plpgsql
    AS $$
DECLARE
    result type_user;
    rec RECORD;
BEGIN
    begin
        result.is_new := true;
        INSERT INTO "Users" (nickname, fullname, about, email)
        VALUES (arg_nickname, arg_fullname, arg_about, arg_email)
        RETURNING nickname, fullname, about, email
        INTO result.nickname, result.fullname, result.about, result.email;
        RETURN next result;
    EXCEPTION
        WHEN unique_violation THEN
            begin
                result.is_new := false;
                FOR rec IN SELECT nickname, fullname, about, email
                    FROM "Users"
                    WHERE lower(nickname) = lower(arg_nickname)
                    OR lower(email) = lower(arg_email)
                LOOP
                    result.nickname := rec.nickname;
                    result.fullname := rec.fullname;
                    result.about := rec.about;
                    result.email := rec.email;
                    RETURN NEXT result;
                END LOOP;
            end;
    end;
END;
$$;


ALTER FUNCTION public.func_user_create(arg_nickname character varying, arg_fullname character varying, arg_about character varying, arg_email character varying) OWNER TO maxim;

--
-- Name: func_user_details(character varying); Type: FUNCTION; Schema: public; Owner: maxim
--

CREATE FUNCTION public.func_user_details(arg_nickname character varying) RETURNS public.type_user
    LANGUAGE plpgsql
    AS $$
DECLARE
    result type_user;
BEGIN
    result.is_new := FALSE;
    SELECT nickname, fullname, about, email
    INTO result.nickname, result.fullname, result.about, result.email
    FROM "Users"
    WHERE lower(nickname) = lower(arg_nickname);
    if not found then
        RAISe no_data_found;
    end if;
    RETURN result;
END;
$$;


ALTER FUNCTION public.func_user_details(arg_nickname character varying) OWNER TO maxim;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: Forums; Type: TABLE; Schema: public; Owner: maxim
--

CREATE TABLE public."Forums" (
    id bigint NOT NULL,
    posts bigint DEFAULT 0 NOT NULL,
    slug character varying(2044) NOT NULL,
    threads integer DEFAULT 0 NOT NULL,
    title character varying(256) NOT NULL,
    "user-id" bigint NOT NULL
);


ALTER TABLE public."Forums" OWNER TO maxim;

--
-- Name: Forum_id_seq; Type: SEQUENCE; Schema: public; Owner: maxim
--

CREATE SEQUENCE public."Forum_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Forum_id_seq" OWNER TO maxim;

--
-- Name: Forum_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: maxim
--

ALTER SEQUENCE public."Forum_id_seq" OWNED BY public."Forums".id;


--
-- Name: Posts; Type: TABLE; Schema: public; Owner: maxim
--

CREATE TABLE public."Posts" (
    id bigint NOT NULL,
    "author-id" bigint NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL,
    "forum-id" bigint NOT NULL,
    "is-edited" boolean DEFAULT false NOT NULL,
    message character varying(2044) NOT NULL,
    "parent-id" bigint,
    "thread-id" bigint NOT NULL,
    path bigint[] DEFAULT '{0}'::bigint[] NOT NULL
);


ALTER TABLE public."Posts" OWNER TO maxim;

--
-- Name: Post_id_seq; Type: SEQUENCE; Schema: public; Owner: maxim
--

CREATE SEQUENCE public."Post_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Post_id_seq" OWNER TO maxim;

--
-- Name: Post_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: maxim
--

ALTER SEQUENCE public."Post_id_seq" OWNED BY public."Posts".id;


--
-- Name: Threads; Type: TABLE; Schema: public; Owner: maxim
--

CREATE TABLE public."Threads" (
    id bigint NOT NULL,
    "author-id" bigint NOT NULL,
    created timestamp with time zone DEFAULT now() NOT NULL,
    "forum-id" bigint NOT NULL,
    message character varying(2044) NOT NULL,
    slug character varying(2044) DEFAULT ''::character varying NOT NULL,
    title character varying(2044) NOT NULL,
    votes integer DEFAULT 0 NOT NULL
);


ALTER TABLE public."Threads" OWNER TO maxim;

--
-- Name: Thread_id_seq; Type: SEQUENCE; Schema: public; Owner: maxim
--

CREATE SEQUENCE public."Thread_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Thread_id_seq" OWNER TO maxim;

--
-- Name: Thread_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: maxim
--

ALTER SEQUENCE public."Thread_id_seq" OWNED BY public."Threads".id;


--
-- Name: Users; Type: TABLE; Schema: public; Owner: maxim
--

CREATE TABLE public."Users" (
    id bigint NOT NULL,
    about character varying(512) NOT NULL,
    email character varying(2044) NOT NULL,
    fullname character varying(128) NOT NULL,
    nickname character varying(2044) NOT NULL,
    "writing-to-forum" bigint[] DEFAULT '{}'::bigint[] NOT NULL
);


ALTER TABLE public."Users" OWNER TO maxim;

--
-- Name: Users_id_seq; Type: SEQUENCE; Schema: public; Owner: maxim
--

CREATE SEQUENCE public."Users_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Users_id_seq" OWNER TO maxim;

--
-- Name: Users_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: maxim
--

ALTER SEQUENCE public."Users_id_seq" OWNED BY public."Users".id;


--
-- Name: Votes; Type: TABLE; Schema: public; Owner: maxim
--

CREATE TABLE public."Votes" (
    id bigint NOT NULL,
    voice public."Vote" NOT NULL,
    "thread-id" bigint NOT NULL,
    "user-id" bigint NOT NULL
);


ALTER TABLE public."Votes" OWNER TO maxim;

--
-- Name: Votes_id_seq; Type: SEQUENCE; Schema: public; Owner: maxim
--

CREATE SEQUENCE public."Votes_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public."Votes_id_seq" OWNER TO maxim;

--
-- Name: Votes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: maxim
--

ALTER SEQUENCE public."Votes_id_seq" OWNED BY public."Votes".id;


--
-- Name: Forums id; Type: DEFAULT; Schema: public; Owner: maxim
--

ALTER TABLE ONLY public."Forums" ALTER COLUMN id SET DEFAULT nextval('public."Forum_id_seq"'::regclass);


--
-- Name: Posts id; Type: DEFAULT; Schema: public; Owner: maxim
--

ALTER TABLE ONLY public."Posts" ALTER COLUMN id SET DEFAULT nextval('public."Post_id_seq"'::regclass);


--
-- Name: Threads id; Type: DEFAULT; Schema: public; Owner: maxim
--

ALTER TABLE ONLY public."Threads" ALTER COLUMN id SET DEFAULT nextval('public."Thread_id_seq"'::regclass);


--
-- Name: Users id; Type: DEFAULT; Schema: public; Owner: maxim
--

ALTER TABLE ONLY public."Users" ALTER COLUMN id SET DEFAULT nextval('public."Users_id_seq"'::regclass);


--
-- Name: Votes id; Type: DEFAULT; Schema: public; Owner: maxim
--

ALTER TABLE ONLY public."Votes" ALTER COLUMN id SET DEFAULT nextval('public."Votes_id_seq"'::regclass);


--
-- Data for Name: Forums; Type: TABLE DATA; Schema: public; Owner: maxim
--

COPY public."Forums" (id, posts, slug, threads, title, "user-id") FROM stdin;
\.


--
-- Data for Name: Posts; Type: TABLE DATA; Schema: public; Owner: maxim
--

COPY public."Posts" (id, "author-id", created, "forum-id", "is-edited", message, "parent-id", "thread-id", path) FROM stdin;
\.


--
-- Data for Name: Threads; Type: TABLE DATA; Schema: public; Owner: maxim
--

COPY public."Threads" (id, "author-id", created, "forum-id", message, slug, title, votes) FROM stdin;
\.


--
-- Data for Name: Users; Type: TABLE DATA; Schema: public; Owner: maxim
--

COPY public."Users" (id, about, email, fullname, nickname, "writing-to-forum") FROM stdin;
\.


--
-- Data for Name: Votes; Type: TABLE DATA; Schema: public; Owner: maxim
--

COPY public."Votes" (id, voice, "thread-id", "user-id") FROM stdin;
\.


--
-- Name: Forum_id_seq; Type: SEQUENCE SET; Schema: public; Owner: maxim
--

SELECT pg_catalog.setval('public."Forum_id_seq"', 18452, true);


--
-- Name: Post_id_seq; Type: SEQUENCE SET; Schema: public; Owner: maxim
--

SELECT pg_catalog.setval('public."Post_id_seq"', 18178485, true);


--
-- Name: Thread_id_seq; Type: SEQUENCE SET; Schema: public; Owner: maxim
--

SELECT pg_catalog.setval('public."Thread_id_seq"', 317187, true);


--
-- Name: Users_id_seq; Type: SEQUENCE SET; Schema: public; Owner: maxim
--

SELECT pg_catalog.setval('public."Users_id_seq"', 96654, true);


--
-- Name: Votes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: maxim
--

SELECT pg_catalog.setval('public."Votes_id_seq"', 2695627, true);


--
-- Name: Forums Forum_pkey; Type: CONSTRAINT; Schema: public; Owner: maxim
--

ALTER TABLE ONLY public."Forums"
    ADD CONSTRAINT "Forum_pkey" PRIMARY KEY (id);


--
-- Name: Posts Post_pkey; Type: CONSTRAINT; Schema: public; Owner: maxim
--

ALTER TABLE ONLY public."Posts"
    ADD CONSTRAINT "Post_pkey" PRIMARY KEY (id);


--
-- Name: Threads Thread_pkey; Type: CONSTRAINT; Schema: public; Owner: maxim
--

ALTER TABLE ONLY public."Threads"
    ADD CONSTRAINT "Thread_pkey" PRIMARY KEY (id);


--
-- Name: Users Users_pkey; Type: CONSTRAINT; Schema: public; Owner: maxim
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "Users_pkey" PRIMARY KEY (id);


--
-- Name: Votes Votes_pkey; Type: CONSTRAINT; Schema: public; Owner: maxim
--

ALTER TABLE ONLY public."Votes"
    ADD CONSTRAINT "Votes_pkey" PRIMARY KEY (id);


--
-- Name: Forums unique_Forum_id; Type: CONSTRAINT; Schema: public; Owner: maxim
--

ALTER TABLE ONLY public."Forums"
    ADD CONSTRAINT "unique_Forum_id" UNIQUE (id);


--
-- Name: Posts unique_Post_id; Type: CONSTRAINT; Schema: public; Owner: maxim
--

ALTER TABLE ONLY public."Posts"
    ADD CONSTRAINT "unique_Post_id" UNIQUE (id);


--
-- Name: Threads unique_Thread_id; Type: CONSTRAINT; Schema: public; Owner: maxim
--

ALTER TABLE ONLY public."Threads"
    ADD CONSTRAINT "unique_Thread_id" UNIQUE (id);


--
-- Name: Users unique_Users_id; Type: CONSTRAINT; Schema: public; Owner: maxim
--

ALTER TABLE ONLY public."Users"
    ADD CONSTRAINT "unique_Users_id" UNIQUE (id);


--
-- Name: Votes unique_Votes_id; Type: CONSTRAINT; Schema: public; Owner: maxim
--

ALTER TABLE ONLY public."Votes"
    ADD CONSTRAINT "unique_Votes_id" UNIQUE (id);


--
-- Name: Votes unique_Votes_user_thread_pair; Type: CONSTRAINT; Schema: public; Owner: maxim
--

ALTER TABLE ONLY public."Votes"
    ADD CONSTRAINT "unique_Votes_user_thread_pair" UNIQUE ("thread-id", "user-id");


--
-- Name: idx_forum_ci_slug; Type: INDEX; Schema: public; Owner: maxim
--

CREATE UNIQUE INDEX idx_forum_ci_slug ON public."Forums" USING btree (lower((slug)::text));


--
-- Name: idx_post_author_id; Type: INDEX; Schema: public; Owner: maxim
--

CREATE INDEX idx_post_author_id ON public."Posts" USING btree ("author-id");


--
-- Name: idx_post_forum_id; Type: INDEX; Schema: public; Owner: maxim
--

CREATE INDEX idx_post_forum_id ON public."Posts" USING btree ("forum-id");


--
-- Name: idx_post_path; Type: INDEX; Schema: public; Owner: maxim
--

CREATE INDEX idx_post_path ON public."Posts" USING btree (path);


--
-- Name: idx_post_thread_id; Type: INDEX; Schema: public; Owner: maxim
--

CREATE INDEX idx_post_thread_id ON public."Posts" USING btree ("thread-id");


--
-- Name: idx_thread_author_id; Type: INDEX; Schema: public; Owner: maxim
--

CREATE INDEX idx_thread_author_id ON public."Threads" USING btree ("author-id");


--
-- Name: idx_thread_ci_slug; Type: INDEX; Schema: public; Owner: maxim
--

CREATE UNIQUE INDEX idx_thread_ci_slug ON public."Threads" USING btree (lower((slug)::text)) WHERE ((slug)::text <> ''::text);


--
-- Name: idx_thread_created; Type: INDEX; Schema: public; Owner: maxim
--

CREATE INDEX idx_thread_created ON public."Threads" USING btree (created);


--
-- Name: idx_thread_forum_id; Type: INDEX; Schema: public; Owner: maxim
--

CREATE INDEX idx_thread_forum_id ON public."Threads" USING btree ("forum-id");


--
-- Name: idx_user_email; Type: INDEX; Schema: public; Owner: maxim
--

CREATE UNIQUE INDEX idx_user_email ON public."Users" USING btree (lower((email)::text));


--
-- Name: idx_user_nickname; Type: INDEX; Schema: public; Owner: maxim
--

CREATE UNIQUE INDEX idx_user_nickname ON public."Users" USING btree (lower((nickname)::text));


--
-- Name: idx_user_writing_to_forum; Type: INDEX; Schema: public; Owner: maxim
--

CREATE INDEX idx_user_writing_to_forum ON public."Users" USING btree (id, "writing-to-forum");


--
-- Name: idx_vote_thread_id; Type: INDEX; Schema: public; Owner: maxim
--

CREATE INDEX idx_vote_thread_id ON public."Votes" USING btree ("thread-id");


--
-- Name: idx_vote_user_id; Type: INDEX; Schema: public; Owner: maxim
--

CREATE INDEX idx_vote_user_id ON public."Votes" USING btree ("user-id");


--
-- Name: Posts trg_add_post_to_forum; Type: TRIGGER; Schema: public; Owner: maxim
--

CREATE TRIGGER trg_add_post_to_forum AFTER INSERT ON public."Posts" FOR EACH ROW EXECUTE PROCEDURE public.func_add_post_to_forum();


--
-- Name: Threads trg_add_thread_to_forum; Type: TRIGGER; Schema: public; Owner: maxim
--

CREATE TRIGGER trg_add_thread_to_forum AFTER INSERT ON public."Threads" FOR EACH ROW EXECUTE PROCEDURE public.func_add_thread_to_forum();


--
-- Name: Votes trg_add_vote_to_thread; Type: TRIGGER; Schema: public; Owner: maxim
--

CREATE TRIGGER trg_add_vote_to_thread AFTER INSERT ON public."Votes" FOR EACH ROW EXECUTE PROCEDURE public.func_add_vote_to_thread();


--
-- Name: Posts trg_check_post_before_adding; Type: TRIGGER; Schema: public; Owner: maxim
--

CREATE TRIGGER trg_check_post_before_adding BEFORE INSERT OR UPDATE ON public."Posts" FOR EACH ROW EXECUTE PROCEDURE public.func_check_post_before_adding();


--
-- Name: Posts trg_convert_post_parent_zero_into_null; Type: TRIGGER; Schema: public; Owner: maxim
--

CREATE TRIGGER trg_convert_post_parent_zero_into_null BEFORE INSERT OR UPDATE ON public."Posts" FOR EACH ROW EXECUTE PROCEDURE public.func_convert_post_parent_zero_into_null();


--
-- Name: Threads trg_delete thread_from_forum; Type: TRIGGER; Schema: public; Owner: maxim
--

CREATE TRIGGER "trg_delete thread_from_forum" AFTER DELETE ON public."Threads" FOR EACH ROW EXECUTE PROCEDURE public.func_delete_thread_from_forum();


--
-- Name: Posts trg_delete_post_from_forum; Type: TRIGGER; Schema: public; Owner: maxim
--

CREATE TRIGGER trg_delete_post_from_forum BEFORE DELETE ON public."Posts" FOR EACH ROW EXECUTE PROCEDURE public.func_delete_post_from_forum();


--
-- Name: Votes trg_delete_vote_from_thread; Type: TRIGGER; Schema: public; Owner: maxim
--

CREATE TRIGGER trg_delete_vote_from_thread AFTER DELETE ON public."Votes" FOR EACH ROW EXECUTE PROCEDURE public.func_delete_vote_from_thread();


--
-- Name: Posts trg_edit_post; Type: TRIGGER; Schema: public; Owner: maxim
--

CREATE TRIGGER trg_edit_post BEFORE UPDATE ON public."Posts" FOR EACH ROW EXECUTE PROCEDURE public.func_edit_post();


--
-- Name: Posts trg_make_post_path; Type: TRIGGER; Schema: public; Owner: maxim
--

CREATE TRIGGER trg_make_post_path BEFORE INSERT ON public."Posts" FOR EACH ROW EXECUTE PROCEDURE public.func_make_path_for_post();


--
-- Name: Votes trg_update_vote; Type: TRIGGER; Schema: public; Owner: maxim
--

CREATE TRIGGER trg_update_vote AFTER UPDATE ON public."Votes" FOR EACH ROW EXECUTE PROCEDURE public.func_update_vote();


--
-- Name: Posts lnk_Forums_Posts; Type: FK CONSTRAINT; Schema: public; Owner: maxim
--

ALTER TABLE ONLY public."Posts"
    ADD CONSTRAINT "lnk_Forums_Posts" FOREIGN KEY ("forum-id") REFERENCES public."Forums"(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: Threads lnk_Forums_Threads; Type: FK CONSTRAINT; Schema: public; Owner: maxim
--

ALTER TABLE ONLY public."Threads"
    ADD CONSTRAINT "lnk_Forums_Threads" FOREIGN KEY ("forum-id") REFERENCES public."Forums"(id) MATCH FULL ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Posts lnk_Posts_Posts; Type: FK CONSTRAINT; Schema: public; Owner: maxim
--

ALTER TABLE ONLY public."Posts"
    ADD CONSTRAINT "lnk_Posts_Posts" FOREIGN KEY ("parent-id") REFERENCES public."Posts"(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: Posts lnk_Threads_Posts; Type: FK CONSTRAINT; Schema: public; Owner: maxim
--

ALTER TABLE ONLY public."Posts"
    ADD CONSTRAINT "lnk_Threads_Posts" FOREIGN KEY ("thread-id") REFERENCES public."Threads"(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: Votes lnk_Threads_Votes; Type: FK CONSTRAINT; Schema: public; Owner: maxim
--

ALTER TABLE ONLY public."Votes"
    ADD CONSTRAINT "lnk_Threads_Votes" FOREIGN KEY ("thread-id") REFERENCES public."Threads"(id) MATCH FULL ON DELETE CASCADE;


--
-- Name: Forums lnk_Users_Forums; Type: FK CONSTRAINT; Schema: public; Owner: maxim
--

ALTER TABLE ONLY public."Forums"
    ADD CONSTRAINT "lnk_Users_Forums" FOREIGN KEY ("user-id") REFERENCES public."Users"(id) MATCH FULL;


--
-- Name: Posts lnk_Users_Posts; Type: FK CONSTRAINT; Schema: public; Owner: maxim
--

ALTER TABLE ONLY public."Posts"
    ADD CONSTRAINT "lnk_Users_Posts" FOREIGN KEY ("author-id") REFERENCES public."Users"(id) MATCH FULL;


--
-- Name: Threads lnk_Users_Threads; Type: FK CONSTRAINT; Schema: public; Owner: maxim
--

ALTER TABLE ONLY public."Threads"
    ADD CONSTRAINT "lnk_Users_Threads" FOREIGN KEY ("author-id") REFERENCES public."Users"(id) MATCH FULL;


--
-- Name: Votes lnk_Users_Votes; Type: FK CONSTRAINT; Schema: public; Owner: maxim
--

ALTER TABLE ONLY public."Votes"
    ADD CONSTRAINT "lnk_Users_Votes" FOREIGN KEY ("user-id") REFERENCES public."Users"(id) MATCH FULL;


--
-- PostgreSQL database dump complete
--

