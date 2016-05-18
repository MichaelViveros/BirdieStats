--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.2
-- Dumped by pg_dump version 9.5.2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
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
-- Name: adminpack; Type: EXTENSION; Schema: -; Owner: 
--

CREATE EXTENSION IF NOT EXISTS adminpack WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION adminpack; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION adminpack IS 'administrative functions for PostgreSQL';


SET search_path = public, pg_catalog;

--
-- Name: get_rounds(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION get_rounds(user_name text) RETURNS TABLE(round_id integer, round_date date, club text, round_course_id integer, course text, tees text, player text, hole integer, yards integer, par integer, strokes integer)
    LANGUAGE sql STABLE STRICT
    AS $$

SELECT  
	round."ID",
	round."Date",
	club."ShortName",
	round_course."ID",
	course."Name",
	tee."Name",
	user_info."Name",
	strokes."HoleNumber", 
	tee_hole."Yards", 
	hole."Par", 
	strokes."Strokes"
FROM 
	"Round" round,
	"Club" club,
	"Course" course,
	"Tee" tee,
	"User" user_info,
	"CourseHole" hole,
	"TeeHole" tee_hole, 
	"RoundStrokes" strokes,
	"RoundCourse" round_course,
	"RoundUser" round_user
WHERE
	--TODO should there be joins here instead of just a = b?
	club."ID" = round."ClubID"
	and round_course."RoundID" = round."ID"
	and course."ID" = round_course."CourseID"
	and tee."ID" = round_course."TeeID"
	and round_user."RoundID" = round."ID"
	and user_info."ID" = round_user."UserID"
	and user_info."Name" LIKE '%' || user_name || '%'
	and strokes."UserID" = user_info."ID"
	and strokes."RoundCourseID" = round_course."ID"
	and tee_hole."TeeID" = tee."ID"
	and tee_hole."Number" = strokes."HoleNumber"
	and hole."CourseID" = course."ID"
	and hole."Number" = strokes."HoleNumber"
ORDER BY
	round."ID" DESC,
	round_course."SequenceNum",
	round_user."ID",
	strokes."HoleNumber";
$$;


ALTER FUNCTION public.get_rounds(user_name text) OWNER TO postgres;

--
-- Name: insert_rounds(date, text, text[], text[], text[], integer[], integer[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION insert_rounds(round_date date, club text, user_names text[], courses text[], tees text[], holes integer[], strokes integer[]) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE

	user_id int;
	user_ids int[];
	club_id int;
	course_id int;
	course_ids int[];
	tee_id int;
	tee_ids int[];
	round_id int;
	round_course_id int;
	round_user_id int; 

BEGIN

	--check if parameters are valid

	--user_names
	FOR i in 1 .. array_length(user_names, 1)
	LOOP
		SELECT INTO user_id "ID" FROM "User" WHERE "Name" = user_names[i];
		IF user_id IS NULL THEN
			RAISE EXCEPTION 'user % does not exist', user_names[i];
			--TODO doesn't seem to return false below, gotta check what gets returned to server
			--RETURN FALSE;
		END IF;	  
		user_ids[i] := user_id;
	END LOOP;
	
	--club
	SELECT INTO club_id "ID" FROM "Club" WHERE "Name" = club OR "ShortName" = club;
	IF club_id IS NULL THEN
		RAISE EXCEPTION 'club % does not exist', club;
	END IF;

	--courses and tees
	FOR i in 1 .. array_length(courses, 1)
	LOOP		
		SELECT INTO course_id "ID" FROM "Course" WHERE "ClubID" = club_id AND "Name" = courses[i];
		IF course_id IS NULL THEN
			RAISE EXCEPTION 'Invalid course % for club %', courses[i], club;
		END IF;
		SELECT INTO tee_id "ID" FROM "Tee" WHERE "CourseID" = course_id AND "Name" = tees[i];
		IF tee_id IS NULL THEN
			RAISE EXCEPTION 'Invalid tee % for course %', tees[i], courses[i];
		END IF;
		course_ids[i] := course_id;
		tee_ids[i] := tee_id;
	END LOOP;

	--TODO: check hole numbers in holes?

	--insert rounds

	--Round
	INSERT INTO "Round" ("Date", "ClubID")
		VALUES (round_date, club_id)
		RETURNING "ID" into round_id;
	RAISE NOTICE 'round_id %', round_id; 

	--RoundUser
	FOR i in 1 .. array_length(user_names, 1) 
	LOOP
		INSERT INTO "RoundUser" ("UserID", "RoundID")
			VALUES (user_ids[i], round_id)
			RETURNING "ID" into round_user_id;
		RAISE NOTICE 'round_user_id %', round_user_id;
	END LOOP;

	--RoundCourse and RoundStrokes
	FOR i in 1 .. array_length(courses, 1) 
	LOOP
		INSERT INTO "RoundCourse" ("RoundID", "CourseID", "TeeID", "SequenceNum")
			VALUES (round_id, course_ids[i], tee_ids[i], i)
			RETURNING "ID" into round_course_id;
		RAISE NOTICE 'round_course_id %', round_course_id;
		--RAISE NOTICE 'holes 1 % - 2 %', array_length(holes, 1), array_length(holes, 2);

		FOR j in 1 .. array_length(user_names, 1)
		LOOP
			FOR k in 1 .. array_length(holes, 2) 
			LOOP
				INSERT INTO "RoundStrokes" ("UserID", "HoleNumber", "Strokes", "RoundCourseID")
					VALUES (user_ids[j], holes[i][k], strokes[i][j][k], round_course_id);
				RAISE NOTICE 'strokes added - %, %, %, %', user_ids[j], holes[i][k], strokes[i][j][k], round_course_id;
			END LOOP;
		END LOOP;
	END LOOP;

	RETURN TRUE;	

END;

$$;


ALTER FUNCTION public.insert_rounds(round_date date, club text, user_names text[], courses text[], tees text[], holes integer[], strokes integer[]) OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: Club; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "Club" (
    "ID" integer NOT NULL,
    "Name" text NOT NULL,
    "ShortName" text,
    "Address" text NOT NULL,
    "City" text NOT NULL,
    "Province" text NOT NULL,
    "Country" text NOT NULL
);


ALTER TABLE "Club" OWNER TO postgres;

--
-- Name: Club_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE "Club_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "Club_ID_seq" OWNER TO postgres;

--
-- Name: Club_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE "Club_ID_seq" OWNED BY "Club"."ID";


--
-- Name: Course; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "Course" (
    "ID" integer NOT NULL,
    "Name" text,
    "ClubID" integer NOT NULL
);


ALTER TABLE "Course" OWNER TO postgres;

--
-- Name: CourseHole; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "CourseHole" (
    "CourseID" integer NOT NULL,
    "Number" integer NOT NULL,
    "Par" integer NOT NULL,
    "Handicap" integer,
    "LadiesPar" integer,
    "LadiesHandicap" integer
);


ALTER TABLE "CourseHole" OWNER TO postgres;

--
-- Name: Course_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE "Course_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "Course_ID_seq" OWNER TO postgres;

--
-- Name: Course_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE "Course_ID_seq" OWNED BY "Course"."ID";


--
-- Name: Round; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "Round" (
    "ID" integer NOT NULL,
    "Date" date NOT NULL,
    "ClubID" integer NOT NULL
);


ALTER TABLE "Round" OWNER TO postgres;

--
-- Name: RoundCourse; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "RoundCourse" (
    "ID" integer NOT NULL,
    "RoundID" integer NOT NULL,
    "CourseID" integer NOT NULL,
    "SequenceNum" integer DEFAULT 1 NOT NULL,
    "TeeID" integer NOT NULL
);


ALTER TABLE "RoundCourse" OWNER TO postgres;

--
-- Name: RoundCourses_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE "RoundCourses_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "RoundCourses_ID_seq" OWNER TO postgres;

--
-- Name: RoundCourses_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE "RoundCourses_ID_seq" OWNED BY "RoundCourse"."ID";


--
-- Name: RoundStrokes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "RoundStrokes" (
    "UserID" integer NOT NULL,
    "HoleNumber" integer NOT NULL,
    "Strokes" integer NOT NULL,
    "RoundCourseID" integer NOT NULL
);


ALTER TABLE "RoundStrokes" OWNER TO postgres;

--
-- Name: RoundUser; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "RoundUser" (
    "ID" integer NOT NULL,
    "UserID" integer NOT NULL,
    "RoundID" integer NOT NULL,
    "TotalStrokes" integer,
    "TotalHoles" integer
);


ALTER TABLE "RoundUser" OWNER TO postgres;

--
-- Name: Round_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE "Round_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "Round_ID_seq" OWNER TO postgres;

--
-- Name: Round_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE "Round_ID_seq" OWNED BY "Round"."ID";


--
-- Name: Score_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE "Score_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "Score_ID_seq" OWNER TO postgres;

--
-- Name: Score_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE "Score_ID_seq" OWNED BY "RoundUser"."ID";


--
-- Name: Tee; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "Tee" (
    "ID" integer NOT NULL,
    "CourseID" integer NOT NULL,
    "Name" text,
    "Slope" double precision,
    "Rating" numeric(3,1),
    "LadiesSlope" double precision,
    "LadiesRating" numeric(2,1),
    "TotalYards" integer NOT NULL
);


ALTER TABLE "Tee" OWNER TO postgres;

--
-- Name: TeeHole; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "TeeHole" (
    "TeeID" integer NOT NULL,
    "Number" integer NOT NULL,
    "Yards" integer NOT NULL
);


ALTER TABLE "TeeHole" OWNER TO postgres;

--
-- Name: Tee_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE "Tee_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "Tee_ID_seq" OWNER TO postgres;

--
-- Name: Tee_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE "Tee_ID_seq" OWNED BY "Tee"."ID";


--
-- Name: User; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE "User" (
    "ID" integer NOT NULL,
    "Name" text NOT NULL,
    "Username" text,
    "Email" text NOT NULL,
    "Handicap" numeric(3,2),
    "Gender" text NOT NULL
);


ALTER TABLE "User" OWNER TO postgres;

--
-- Name: User_ID_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE "User_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "User_ID_seq" OWNER TO postgres;

--
-- Name: User_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE "User_ID_seq" OWNED BY "User"."ID";


--
-- Name: ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "Club" ALTER COLUMN "ID" SET DEFAULT nextval('"Club_ID_seq"'::regclass);


--
-- Name: ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "Course" ALTER COLUMN "ID" SET DEFAULT nextval('"Course_ID_seq"'::regclass);


--
-- Name: ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "Round" ALTER COLUMN "ID" SET DEFAULT nextval('"Round_ID_seq"'::regclass);


--
-- Name: ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "RoundCourse" ALTER COLUMN "ID" SET DEFAULT nextval('"RoundCourses_ID_seq"'::regclass);


--
-- Name: ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "RoundUser" ALTER COLUMN "ID" SET DEFAULT nextval('"Score_ID_seq"'::regclass);


--
-- Name: ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "Tee" ALTER COLUMN "ID" SET DEFAULT nextval('"Tee_ID_seq"'::regclass);


--
-- Name: ID; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "User" ALTER COLUMN "ID" SET DEFAULT nextval('"User_ID_seq"'::regclass);


--
-- Data for Name: Club; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "Club" VALUES (1, 'Chedoke Golf Club', 'Chedoke', '563 Aberdeen Avenue', 'Hamilton', 'ON', 'Canada');


--
-- Name: Club_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('"Club_ID_seq"', 1, true);


--
-- Data for Name: Course; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "Course" VALUES (1, 'Beddoe', 1);
INSERT INTO "Course" VALUES (2, 'Martin', 1);


--
-- Data for Name: CourseHole; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "CourseHole" VALUES (1, 1, 4, 9, 4, NULL);
INSERT INTO "CourseHole" VALUES (1, 2, 4, 3, 4, NULL);
INSERT INTO "CourseHole" VALUES (1, 3, 3, 15, 3, NULL);
INSERT INTO "CourseHole" VALUES (1, 4, 4, 5, 4, NULL);
INSERT INTO "CourseHole" VALUES (1, 5, 5, 11, 5, NULL);
INSERT INTO "CourseHole" VALUES (1, 6, 3, 7, 3, NULL);
INSERT INTO "CourseHole" VALUES (1, 7, 4, 1, 5, NULL);
INSERT INTO "CourseHole" VALUES (1, 8, 3, 17, 3, NULL);
INSERT INTO "CourseHole" VALUES (1, 9, 5, 13, 5, NULL);
INSERT INTO "CourseHole" VALUES (1, 11, 4, 14, 4, NULL);
INSERT INTO "CourseHole" VALUES (1, 12, 4, 12, 4, NULL);
INSERT INTO "CourseHole" VALUES (1, 13, 3, 18, 3, NULL);
INSERT INTO "CourseHole" VALUES (1, 14, 5, 8, 5, NULL);
INSERT INTO "CourseHole" VALUES (1, 15, 4, 16, 4, NULL);
INSERT INTO "CourseHole" VALUES (1, 16, 4, 10, 4, NULL);
INSERT INTO "CourseHole" VALUES (1, 17, 3, 6, 3, NULL);
INSERT INTO "CourseHole" VALUES (1, 18, 4, 4, 4, NULL);
INSERT INTO "CourseHole" VALUES (1, 10, 4, 2, 5, NULL);
INSERT INTO "CourseHole" VALUES (2, 1, 4, 13, 4, NULL);
INSERT INTO "CourseHole" VALUES (2, 2, 5, 9, 5, NULL);
INSERT INTO "CourseHole" VALUES (2, 3, 3, 15, 4, NULL);
INSERT INTO "CourseHole" VALUES (2, 4, 3, 17, 3, NULL);
INSERT INTO "CourseHole" VALUES (2, 5, 4, 11, 4, NULL);
INSERT INTO "CourseHole" VALUES (2, 6, 4, 3, 5, NULL);
INSERT INTO "CourseHole" VALUES (2, 7, 5, 7, 5, NULL);
INSERT INTO "CourseHole" VALUES (2, 8, 5, 1, 5, NULL);
INSERT INTO "CourseHole" VALUES (2, 9, 4, 5, 4, NULL);
INSERT INTO "CourseHole" VALUES (2, 10, 3, 18, 3, NULL);
INSERT INTO "CourseHole" VALUES (2, 11, 4, 4, 4, NULL);
INSERT INTO "CourseHole" VALUES (2, 12, 4, 2, 4, NULL);
INSERT INTO "CourseHole" VALUES (2, 13, 4, 10, 4, NULL);
INSERT INTO "CourseHole" VALUES (2, 14, 4, 14, 4, NULL);
INSERT INTO "CourseHole" VALUES (2, 15, 4, 6, 4, NULL);
INSERT INTO "CourseHole" VALUES (2, 16, 3, 16, 3, NULL);
INSERT INTO "CourseHole" VALUES (2, 17, 3, 8, 3, NULL);
INSERT INTO "CourseHole" VALUES (2, 18, 4, 12, 4, NULL);


--
-- Name: Course_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('"Course_ID_seq"', 2, true);


--
-- Data for Name: Round; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "Round" VALUES (43, '2016-05-15', 1);
INSERT INTO "Round" VALUES (44, '2016-05-13', 1);
INSERT INTO "Round" VALUES (45, '2016-05-11', 1);
INSERT INTO "Round" VALUES (46, '2016-05-10', 1);
INSERT INTO "Round" VALUES (47, '2016-05-16', 1);
INSERT INTO "Round" VALUES (48, '2016-05-16', 1);
INSERT INTO "Round" VALUES (49, '2016-05-16', 1);
INSERT INTO "Round" VALUES (50, '2016-05-07', 1);
INSERT INTO "Round" VALUES (51, '2016-05-17', 1);


--
-- Data for Name: RoundCourse; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "RoundCourse" VALUES (53, 43, 2, 1, 5);
INSERT INTO "RoundCourse" VALUES (54, 44, 2, 1, 6);
INSERT INTO "RoundCourse" VALUES (55, 45, 1, 1, 1);
INSERT INTO "RoundCourse" VALUES (56, 45, 1, 2, 3);
INSERT INTO "RoundCourse" VALUES (57, 46, 2, 1, 5);
INSERT INTO "RoundCourse" VALUES (58, 46, 1, 2, 4);
INSERT INTO "RoundCourse" VALUES (59, 47, 1, 1, 3);
INSERT INTO "RoundCourse" VALUES (60, 48, 2, 1, 6);
INSERT INTO "RoundCourse" VALUES (61, 49, 2, 1, 6);
INSERT INTO "RoundCourse" VALUES (62, 49, 1, 2, 3);
INSERT INTO "RoundCourse" VALUES (63, 50, 1, 1, 4);
INSERT INTO "RoundCourse" VALUES (64, 51, 2, 1, 6);


--
-- Name: RoundCourses_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('"RoundCourses_ID_seq"', 64, true);


--
-- Data for Name: RoundStrokes; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "RoundStrokes" VALUES (1, 1, 5, 53);
INSERT INTO "RoundStrokes" VALUES (1, 2, 4, 53);
INSERT INTO "RoundStrokes" VALUES (1, 3, 8, 53);
INSERT INTO "RoundStrokes" VALUES (1, 4, 7, 53);
INSERT INTO "RoundStrokes" VALUES (1, 5, 3, 53);
INSERT INTO "RoundStrokes" VALUES (1, 6, 6, 53);
INSERT INTO "RoundStrokes" VALUES (1, 7, 8, 53);
INSERT INTO "RoundStrokes" VALUES (1, 8, 2, 53);
INSERT INTO "RoundStrokes" VALUES (1, 9, 8, 53);
INSERT INTO "RoundStrokes" VALUES (1, 10, 7, 53);
INSERT INTO "RoundStrokes" VALUES (1, 11, 4, 53);
INSERT INTO "RoundStrokes" VALUES (1, 12, 5, 53);
INSERT INTO "RoundStrokes" VALUES (1, 13, 3, 53);
INSERT INTO "RoundStrokes" VALUES (1, 14, 2, 53);
INSERT INTO "RoundStrokes" VALUES (1, 15, 8, 53);
INSERT INTO "RoundStrokes" VALUES (1, 16, 5, 53);
INSERT INTO "RoundStrokes" VALUES (1, 17, 8, 53);
INSERT INTO "RoundStrokes" VALUES (1, 18, 8, 53);
INSERT INTO "RoundStrokes" VALUES (1, 1, 4, 54);
INSERT INTO "RoundStrokes" VALUES (1, 2, 5, 54);
INSERT INTO "RoundStrokes" VALUES (1, 3, 6, 54);
INSERT INTO "RoundStrokes" VALUES (2, 1, 3, 54);
INSERT INTO "RoundStrokes" VALUES (2, 2, 8, 54);
INSERT INTO "RoundStrokes" VALUES (2, 3, 5, 54);
INSERT INTO "RoundStrokes" VALUES (1, 1, 4, 55);
INSERT INTO "RoundStrokes" VALUES (1, 2, 6, 55);
INSERT INTO "RoundStrokes" VALUES (1, 1, 5, 56);
INSERT INTO "RoundStrokes" VALUES (1, 2, 3, 56);
INSERT INTO "RoundStrokes" VALUES (3, 1, 4, 57);
INSERT INTO "RoundStrokes" VALUES (3, 2, 5, 57);
INSERT INTO "RoundStrokes" VALUES (3, 3, 6, 57);
INSERT INTO "RoundStrokes" VALUES (1, 1, 7, 57);
INSERT INTO "RoundStrokes" VALUES (1, 2, 8, 57);
INSERT INTO "RoundStrokes" VALUES (1, 3, 9, 57);
INSERT INTO "RoundStrokes" VALUES (2, 1, 1, 57);
INSERT INTO "RoundStrokes" VALUES (2, 2, 2, 57);
INSERT INTO "RoundStrokes" VALUES (2, 3, 3, 57);
INSERT INTO "RoundStrokes" VALUES (3, 1, 6, 58);
INSERT INTO "RoundStrokes" VALUES (3, 2, 4, 58);
INSERT INTO "RoundStrokes" VALUES (3, 3, 5, 58);
INSERT INTO "RoundStrokes" VALUES (1, 1, 5, 58);
INSERT INTO "RoundStrokes" VALUES (1, 2, 6, 58);
INSERT INTO "RoundStrokes" VALUES (1, 3, 4, 58);
INSERT INTO "RoundStrokes" VALUES (2, 1, 2, 58);
INSERT INTO "RoundStrokes" VALUES (2, 2, 8, 58);
INSERT INTO "RoundStrokes" VALUES (2, 3, 5, 58);
INSERT INTO "RoundStrokes" VALUES (3, 1, 6, 59);
INSERT INTO "RoundStrokes" VALUES (3, 2, 5, 59);
INSERT INTO "RoundStrokes" VALUES (3, 3, 4, 59);
INSERT INTO "RoundStrokes" VALUES (3, 4, 6, 59);
INSERT INTO "RoundStrokes" VALUES (2, 1, 5, 60);
INSERT INTO "RoundStrokes" VALUES (2, 2, 5, 60);
INSERT INTO "RoundStrokes" VALUES (2, 1, 5, 61);
INSERT INTO "RoundStrokes" VALUES (2, 2, 4, 61);
INSERT INTO "RoundStrokes" VALUES (2, 3, 3, 61);
INSERT INTO "RoundStrokes" VALUES (3, 1, 8, 61);
INSERT INTO "RoundStrokes" VALUES (3, 2, 6, 61);
INSERT INTO "RoundStrokes" VALUES (3, 3, 2, 61);
INSERT INTO "RoundStrokes" VALUES (2, 1, 8, 62);
INSERT INTO "RoundStrokes" VALUES (2, 2, 7, 62);
INSERT INTO "RoundStrokes" VALUES (2, 3, 4, 62);
INSERT INTO "RoundStrokes" VALUES (3, 1, 5, 62);
INSERT INTO "RoundStrokes" VALUES (3, 2, 6, 62);
INSERT INTO "RoundStrokes" VALUES (3, 3, 5, 62);
INSERT INTO "RoundStrokes" VALUES (3, 1, 5, 63);
INSERT INTO "RoundStrokes" VALUES (3, 2, 4, 63);
INSERT INTO "RoundStrokes" VALUES (1, 1, 4, 64);
INSERT INTO "RoundStrokes" VALUES (1, 2, 6, 64);
INSERT INTO "RoundStrokes" VALUES (1, 3, 3, 64);


--
-- Data for Name: RoundUser; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "RoundUser" VALUES (49, 1, 43, NULL, NULL);
INSERT INTO "RoundUser" VALUES (50, 1, 44, NULL, NULL);
INSERT INTO "RoundUser" VALUES (51, 2, 44, NULL, NULL);
INSERT INTO "RoundUser" VALUES (52, 1, 45, NULL, NULL);
INSERT INTO "RoundUser" VALUES (53, 3, 46, NULL, NULL);
INSERT INTO "RoundUser" VALUES (54, 1, 46, NULL, NULL);
INSERT INTO "RoundUser" VALUES (55, 2, 46, NULL, NULL);
INSERT INTO "RoundUser" VALUES (56, 3, 47, NULL, NULL);
INSERT INTO "RoundUser" VALUES (57, 2, 48, NULL, NULL);
INSERT INTO "RoundUser" VALUES (58, 2, 49, NULL, NULL);
INSERT INTO "RoundUser" VALUES (59, 3, 49, NULL, NULL);
INSERT INTO "RoundUser" VALUES (60, 3, 50, NULL, NULL);
INSERT INTO "RoundUser" VALUES (61, 1, 51, NULL, NULL);


--
-- Name: Round_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('"Round_ID_seq"', 51, true);


--
-- Name: Score_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('"Score_ID_seq"', 61, true);


--
-- Data for Name: Tee; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "Tee" VALUES (1, 1, 'Blue', 119, 69.2, NULL, NULL, 6084);
INSERT INTO "Tee" VALUES (3, 1, 'White', 116, 67.9, NULL, NULL, 5773);
INSERT INTO "Tee" VALUES (4, 1, 'Red', 113, 66.3, NULL, NULL, 5464);
INSERT INTO "Tee" VALUES (5, 2, 'Blue', 110, 67.1, NULL, NULL, 5745);
INSERT INTO "Tee" VALUES (6, 2, 'Red', 108, 66.0, NULL, NULL, 5505);


--
-- Data for Name: TeeHole; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "TeeHole" VALUES (1, 1, 342);
INSERT INTO "TeeHole" VALUES (1, 2, 385);
INSERT INTO "TeeHole" VALUES (1, 3, 176);
INSERT INTO "TeeHole" VALUES (1, 4, 357);
INSERT INTO "TeeHole" VALUES (1, 5, 459);
INSERT INTO "TeeHole" VALUES (1, 6, 206);
INSERT INTO "TeeHole" VALUES (1, 7, 441);
INSERT INTO "TeeHole" VALUES (1, 8, 138);
INSERT INTO "TeeHole" VALUES (1, 9, 444);
INSERT INTO "TeeHole" VALUES (1, 10, 454);
INSERT INTO "TeeHole" VALUES (1, 11, 370);
INSERT INTO "TeeHole" VALUES (1, 12, 352);
INSERT INTO "TeeHole" VALUES (1, 13, 172);
INSERT INTO "TeeHole" VALUES (1, 14, 516);
INSERT INTO "TeeHole" VALUES (1, 15, 274);
INSERT INTO "TeeHole" VALUES (1, 16, 356);
INSERT INTO "TeeHole" VALUES (1, 17, 202);
INSERT INTO "TeeHole" VALUES (1, 18, 430);
INSERT INTO "TeeHole" VALUES (3, 1, 322);
INSERT INTO "TeeHole" VALUES (3, 2, 355);
INSERT INTO "TeeHole" VALUES (3, 3, 157);
INSERT INTO "TeeHole" VALUES (3, 4, 353);
INSERT INTO "TeeHole" VALUES (3, 5, 443);
INSERT INTO "TeeHole" VALUES (3, 6, 197);
INSERT INTO "TeeHole" VALUES (3, 7, 426);
INSERT INTO "TeeHole" VALUES (3, 8, 130);
INSERT INTO "TeeHole" VALUES (3, 9, 432);
INSERT INTO "TeeHole" VALUES (3, 10, 436);
INSERT INTO "TeeHole" VALUES (3, 11, 345);
INSERT INTO "TeeHole" VALUES (3, 12, 340);
INSERT INTO "TeeHole" VALUES (3, 13, 165);
INSERT INTO "TeeHole" VALUES (3, 14, 492);
INSERT INTO "TeeHole" VALUES (3, 15, 253);
INSERT INTO "TeeHole" VALUES (3, 16, 340);
INSERT INTO "TeeHole" VALUES (3, 17, 187);
INSERT INTO "TeeHole" VALUES (3, 18, 400);
INSERT INTO "TeeHole" VALUES (4, 1, 282);
INSERT INTO "TeeHole" VALUES (4, 2, 343);
INSERT INTO "TeeHole" VALUES (4, 3, 122);
INSERT INTO "TeeHole" VALUES (4, 4, 353);
INSERT INTO "TeeHole" VALUES (4, 5, 427);
INSERT INTO "TeeHole" VALUES (4, 6, 190);
INSERT INTO "TeeHole" VALUES (4, 7, 426);
INSERT INTO "TeeHole" VALUES (4, 8, 122);
INSERT INTO "TeeHole" VALUES (4, 9, 414);
INSERT INTO "TeeHole" VALUES (4, 10, 428);
INSERT INTO "TeeHole" VALUES (4, 11, 345);
INSERT INTO "TeeHole" VALUES (4, 12, 340);
INSERT INTO "TeeHole" VALUES (4, 13, 153);
INSERT INTO "TeeHole" VALUES (4, 14, 482);
INSERT INTO "TeeHole" VALUES (4, 15, 207);
INSERT INTO "TeeHole" VALUES (4, 16, 290);
INSERT INTO "TeeHole" VALUES (4, 17, 176);
INSERT INTO "TeeHole" VALUES (4, 18, 364);
INSERT INTO "TeeHole" VALUES (5, 1, 326);
INSERT INTO "TeeHole" VALUES (5, 9, 315);
INSERT INTO "TeeHole" VALUES (5, 2, 491);
INSERT INTO "TeeHole" VALUES (5, 3, 260);
INSERT INTO "TeeHole" VALUES (5, 4, 172);
INSERT INTO "TeeHole" VALUES (5, 5, 353);
INSERT INTO "TeeHole" VALUES (5, 6, 424);
INSERT INTO "TeeHole" VALUES (5, 7, 498);
INSERT INTO "TeeHole" VALUES (5, 8, 485);
INSERT INTO "TeeHole" VALUES (5, 10, 150);
INSERT INTO "TeeHole" VALUES (5, 11, 370);
INSERT INTO "TeeHole" VALUES (5, 12, 420);
INSERT INTO "TeeHole" VALUES (5, 13, 271);
INSERT INTO "TeeHole" VALUES (5, 14, 252);
INSERT INTO "TeeHole" VALUES (5, 15, 357);
INSERT INTO "TeeHole" VALUES (5, 16, 127);
INSERT INTO "TeeHole" VALUES (5, 17, 215);
INSERT INTO "TeeHole" VALUES (5, 18, 259);
INSERT INTO "TeeHole" VALUES (6, 1, 291);
INSERT INTO "TeeHole" VALUES (6, 2, 478);
INSERT INTO "TeeHole" VALUES (6, 3, 250);
INSERT INTO "TeeHole" VALUES (6, 4, 165);
INSERT INTO "TeeHole" VALUES (6, 5, 341);
INSERT INTO "TeeHole" VALUES (6, 6, 411);
INSERT INTO "TeeHole" VALUES (6, 7, 493);
INSERT INTO "TeeHole" VALUES (6, 8, 480);
INSERT INTO "TeeHole" VALUES (6, 9, 303);
INSERT INTO "TeeHole" VALUES (6, 10, 135);
INSERT INTO "TeeHole" VALUES (6, 11, 358);
INSERT INTO "TeeHole" VALUES (6, 12, 395);
INSERT INTO "TeeHole" VALUES (6, 13, 258);
INSERT INTO "TeeHole" VALUES (6, 14, 240);
INSERT INTO "TeeHole" VALUES (6, 15, 350);
INSERT INTO "TeeHole" VALUES (6, 16, 120);
INSERT INTO "TeeHole" VALUES (6, 17, 193);
INSERT INTO "TeeHole" VALUES (6, 18, 244);


--
-- Name: Tee_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('"Tee_ID_seq"', 6, true);


--
-- Data for Name: User; Type: TABLE DATA; Schema: public; Owner: postgres
--

INSERT INTO "User" VALUES (1, 'Michael Viveros', 'mikevman7', 'michaelviveros@gmail.com', NULL, 'Male');
INSERT INTO "User" VALUES (2, 'Roman Viveros', 'rviveros', 'rviveros@ms.mcmaster.ca', NULL, 'Male');
INSERT INTO "User" VALUES (3, 'test 1', 'test1', 'test1@hotmail.com', NULL, 'Male');


--
-- Name: User_ID_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('"User_ID_seq"', 2, true);


--
-- Name: Club_PK; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "Club"
    ADD CONSTRAINT "Club_PK" PRIMARY KEY ("ID");


--
-- Name: Club_UNIQUE_Name; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "Club"
    ADD CONSTRAINT "Club_UNIQUE_Name" UNIQUE ("Name");


--
-- Name: Club_UNIQUE_ShortName; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "Club"
    ADD CONSTRAINT "Club_UNIQUE_ShortName" UNIQUE ("ShortName");


--
-- Name: CourseHole_PK; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "CourseHole"
    ADD CONSTRAINT "CourseHole_PK" PRIMARY KEY ("CourseID", "Number");


--
-- Name: Course_PK; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "Course"
    ADD CONSTRAINT "Course_PK" PRIMARY KEY ("ID");


--
-- Name: RoundCourse_PK; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "RoundCourse"
    ADD CONSTRAINT "RoundCourse_PK" PRIMARY KEY ("ID");


--
-- Name: RoundCourse_UNIQUE; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "RoundCourse"
    ADD CONSTRAINT "RoundCourse_UNIQUE" UNIQUE ("RoundID", "SequenceNum");


--
-- Name: RoundStrokes_PK; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "RoundStrokes"
    ADD CONSTRAINT "RoundStrokes_PK" PRIMARY KEY ("UserID", "RoundCourseID", "HoleNumber");


--
-- Name: RoundUser_PK; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "RoundUser"
    ADD CONSTRAINT "RoundUser_PK" PRIMARY KEY ("ID");


--
-- Name: RoundUser_UNIQUE; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "RoundUser"
    ADD CONSTRAINT "RoundUser_UNIQUE" UNIQUE ("UserID", "RoundID");


--
-- Name: Round_PK; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "Round"
    ADD CONSTRAINT "Round_PK" PRIMARY KEY ("ID");


--
-- Name: TeeHole_PK; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "TeeHole"
    ADD CONSTRAINT "TeeHole_PK" PRIMARY KEY ("TeeID", "Number");


--
-- Name: TeeHole_UNIQUE; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "TeeHole"
    ADD CONSTRAINT "TeeHole_UNIQUE" UNIQUE ("TeeID", "Number");


--
-- Name: Tee_PK; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "Tee"
    ADD CONSTRAINT "Tee_PK" PRIMARY KEY ("ID");


--
-- Name: Tee_UNIQUE; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "Tee"
    ADD CONSTRAINT "Tee_UNIQUE" UNIQUE ("CourseID", "Name");


--
-- Name: User_PK; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "User"
    ADD CONSTRAINT "User_PK" PRIMARY KEY ("ID");


--
-- Name: User_UNIQUE; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "User"
    ADD CONSTRAINT "User_UNIQUE" UNIQUE ("Username");


--
-- Name: fki_RoundCourses_FK_TeeID; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX "fki_RoundCourses_FK_TeeID" ON "RoundCourse" USING btree ("TeeID");


--
-- Name: CourseHole_FK_CourseID; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "CourseHole"
    ADD CONSTRAINT "CourseHole_FK_CourseID" FOREIGN KEY ("CourseID") REFERENCES "Course"("ID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Course_FK_ClubID; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "Course"
    ADD CONSTRAINT "Course_FK_ClubID" FOREIGN KEY ("ClubID") REFERENCES "Club"("ID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: RoundCourse_FK_CourseID; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "RoundCourse"
    ADD CONSTRAINT "RoundCourse_FK_CourseID" FOREIGN KEY ("CourseID") REFERENCES "Course"("ID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: RoundCourse_FK_RoundID; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "RoundCourse"
    ADD CONSTRAINT "RoundCourse_FK_RoundID" FOREIGN KEY ("RoundID") REFERENCES "Round"("ID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: RoundCourse_FK_TeeID; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "RoundCourse"
    ADD CONSTRAINT "RoundCourse_FK_TeeID" FOREIGN KEY ("TeeID") REFERENCES "Tee"("ID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: RoundStrokes_FK_RoundCourseID; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "RoundStrokes"
    ADD CONSTRAINT "RoundStrokes_FK_RoundCourseID" FOREIGN KEY ("RoundCourseID") REFERENCES "RoundCourse"("ID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: RoundStrokes_FK_UserID; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "RoundStrokes"
    ADD CONSTRAINT "RoundStrokes_FK_UserID" FOREIGN KEY ("UserID") REFERENCES "User"("ID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: RoundUser_FK_RoundID; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "RoundUser"
    ADD CONSTRAINT "RoundUser_FK_RoundID" FOREIGN KEY ("RoundID") REFERENCES "Round"("ID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: RoundUser_FK_UserID; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "RoundUser"
    ADD CONSTRAINT "RoundUser_FK_UserID" FOREIGN KEY ("UserID") REFERENCES "User"("ID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Round_FK_ClubID; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "Round"
    ADD CONSTRAINT "Round_FK_ClubID" FOREIGN KEY ("ClubID") REFERENCES "Club"("ID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: TeeHole_FK_TeeID; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "TeeHole"
    ADD CONSTRAINT "TeeHole_FK_TeeID" FOREIGN KEY ("TeeID") REFERENCES "Tee"("ID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Tee_FK_CourseID; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY "Tee"
    ADD CONSTRAINT "Tee_FK_CourseID" FOREIGN KEY ("CourseID") REFERENCES "Course"("ID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: public; Type: ACL; Schema: -; Owner: postgres
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM postgres;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

