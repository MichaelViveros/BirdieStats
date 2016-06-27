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
-- Name: ddp6mfpbcolv0d; Type: DATABASE; Schema: -; Owner: wjgvsmhxtynijy
--

CREATE DATABASE ddp6mfpbcolv0d;


ALTER DATABASE ddp6mfpbcolv0d OWNER TO wjgvsmhxtynijy;

\connect ddp6mfpbcolv0d

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


SET search_path = public, pg_catalog;

--
-- Name: get_clubs(); Type: FUNCTION; Schema: public; Owner: wjgvsmhxtynijy
--

CREATE FUNCTION get_clubs() RETURNS TABLE(club_id integer, club text, course_id integer, course text, tee_id integer, tees text)
    LANGUAGE sql STABLE STRICT
    AS $$



SELECT  

	club."ID",

	club."ShortName",

	course."ID",

	course."Name",

	tee."ID",

	tee."Name"

FROM 

	"Club" club,

	"Course" course,

	"Tee" tee

WHERE

	course."ClubID" = club."ID"

	and tee."CourseID" = course."ID"

ORDER BY

	club."ShortName",

	course."Name",

	-- use tee."ID" since tees get inserted into the db from largest to smallest

	-- and this is how golfers are used to seeing tees on the scorecard

	tee."ID"



$$;


ALTER FUNCTION public.get_clubs() OWNER TO wjgvsmhxtynijy;

--
-- Name: get_players(); Type: FUNCTION; Schema: public; Owner: wjgvsmhxtynijy
--

CREATE FUNCTION get_players() RETURNS TABLE(name text)
    LANGUAGE sql STABLE STRICT
    AS $$



SELECT  

	user_info."Name"

FROM 

	"User" user_info

ORDER BY

	user_info."Name"



$$;


ALTER FUNCTION public.get_players() OWNER TO wjgvsmhxtynijy;

--
-- Name: get_rounds(text); Type: FUNCTION; Schema: public; Owner: wjgvsmhxtynijy
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


ALTER FUNCTION public.get_rounds(user_name text) OWNER TO wjgvsmhxtynijy;

--
-- Name: insert_rounds(date, text, text[], text[], text[], integer[], integer[]); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION insert_rounds(round_date date, club text, user_names text[], courses text[], tees text[], holeflags integer[], strokes integer[]) RETURNS boolean
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

	--TODO: check hole numbers in holes

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

		FOR j in 1 .. array_length(user_names, 1)
		LOOP
			FOR k in 1 .. 18 
			LOOP
				IF holeFlags[i][k] = 1 THEN
					INSERT INTO "RoundStrokes" ("UserID", "HoleNumber", "Strokes", "RoundCourseID")
						VALUES (user_ids[j], k, strokes[i][j][k], round_course_id);
					RAISE NOTICE 'strokes added - %, %, %, %', user_ids[j], k, strokes[i][j][k], round_course_id;
				END IF;
			END LOOP;
		END LOOP;
	END LOOP;

	RETURN TRUE;	

END;

$$;


ALTER FUNCTION public.insert_rounds(round_date date, club text, user_names text[], courses text[], tees text[], holeflags integer[], strokes integer[]) OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: Club; Type: TABLE; Schema: public; Owner: wjgvsmhxtynijy
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


ALTER TABLE "Club" OWNER TO wjgvsmhxtynijy;

--
-- Name: Club_ID_seq; Type: SEQUENCE; Schema: public; Owner: wjgvsmhxtynijy
--

CREATE SEQUENCE "Club_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "Club_ID_seq" OWNER TO wjgvsmhxtynijy;

--
-- Name: Club_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER SEQUENCE "Club_ID_seq" OWNED BY "Club"."ID";


--
-- Name: Course; Type: TABLE; Schema: public; Owner: wjgvsmhxtynijy
--

CREATE TABLE "Course" (
    "ID" integer NOT NULL,
    "Name" text,
    "ClubID" integer NOT NULL
);


ALTER TABLE "Course" OWNER TO wjgvsmhxtynijy;

--
-- Name: CourseHole; Type: TABLE; Schema: public; Owner: wjgvsmhxtynijy
--

CREATE TABLE "CourseHole" (
    "CourseID" integer NOT NULL,
    "Number" integer NOT NULL,
    "Par" integer NOT NULL,
    "Handicap" integer,
    "LadiesPar" integer,
    "LadiesHandicap" integer
);


ALTER TABLE "CourseHole" OWNER TO wjgvsmhxtynijy;

--
-- Name: Course_ID_seq; Type: SEQUENCE; Schema: public; Owner: wjgvsmhxtynijy
--

CREATE SEQUENCE "Course_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "Course_ID_seq" OWNER TO wjgvsmhxtynijy;

--
-- Name: Course_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER SEQUENCE "Course_ID_seq" OWNED BY "Course"."ID";


--
-- Name: Round; Type: TABLE; Schema: public; Owner: wjgvsmhxtynijy
--

CREATE TABLE "Round" (
    "ID" integer NOT NULL,
    "Date" date NOT NULL,
    "ClubID" integer NOT NULL
);


ALTER TABLE "Round" OWNER TO wjgvsmhxtynijy;

--
-- Name: RoundCourse; Type: TABLE; Schema: public; Owner: wjgvsmhxtynijy
--

CREATE TABLE "RoundCourse" (
    "ID" integer NOT NULL,
    "RoundID" integer NOT NULL,
    "CourseID" integer NOT NULL,
    "SequenceNum" integer DEFAULT 1 NOT NULL,
    "TeeID" integer NOT NULL
);


ALTER TABLE "RoundCourse" OWNER TO wjgvsmhxtynijy;

--
-- Name: RoundCourses_ID_seq; Type: SEQUENCE; Schema: public; Owner: wjgvsmhxtynijy
--

CREATE SEQUENCE "RoundCourses_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "RoundCourses_ID_seq" OWNER TO wjgvsmhxtynijy;

--
-- Name: RoundCourses_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER SEQUENCE "RoundCourses_ID_seq" OWNED BY "RoundCourse"."ID";


--
-- Name: RoundStrokes; Type: TABLE; Schema: public; Owner: wjgvsmhxtynijy
--

CREATE TABLE "RoundStrokes" (
    "UserID" integer NOT NULL,
    "HoleNumber" integer NOT NULL,
    "Strokes" integer NOT NULL,
    "RoundCourseID" integer NOT NULL
);


ALTER TABLE "RoundStrokes" OWNER TO wjgvsmhxtynijy;

--
-- Name: RoundUser; Type: TABLE; Schema: public; Owner: wjgvsmhxtynijy
--

CREATE TABLE "RoundUser" (
    "ID" integer NOT NULL,
    "UserID" integer NOT NULL,
    "RoundID" integer NOT NULL,
    "TotalStrokes" integer,
    "TotalHoles" integer
);


ALTER TABLE "RoundUser" OWNER TO wjgvsmhxtynijy;

--
-- Name: Round_ID_seq; Type: SEQUENCE; Schema: public; Owner: wjgvsmhxtynijy
--

CREATE SEQUENCE "Round_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "Round_ID_seq" OWNER TO wjgvsmhxtynijy;

--
-- Name: Round_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER SEQUENCE "Round_ID_seq" OWNED BY "Round"."ID";


--
-- Name: Score_ID_seq; Type: SEQUENCE; Schema: public; Owner: wjgvsmhxtynijy
--

CREATE SEQUENCE "Score_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "Score_ID_seq" OWNER TO wjgvsmhxtynijy;

--
-- Name: Score_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER SEQUENCE "Score_ID_seq" OWNED BY "RoundUser"."ID";


--
-- Name: Tee; Type: TABLE; Schema: public; Owner: wjgvsmhxtynijy
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


ALTER TABLE "Tee" OWNER TO wjgvsmhxtynijy;

--
-- Name: TeeHole; Type: TABLE; Schema: public; Owner: wjgvsmhxtynijy
--

CREATE TABLE "TeeHole" (
    "TeeID" integer NOT NULL,
    "Number" integer NOT NULL,
    "Yards" integer NOT NULL
);


ALTER TABLE "TeeHole" OWNER TO wjgvsmhxtynijy;

--
-- Name: Tee_ID_seq; Type: SEQUENCE; Schema: public; Owner: wjgvsmhxtynijy
--

CREATE SEQUENCE "Tee_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "Tee_ID_seq" OWNER TO wjgvsmhxtynijy;

--
-- Name: Tee_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER SEQUENCE "Tee_ID_seq" OWNED BY "Tee"."ID";


--
-- Name: User; Type: TABLE; Schema: public; Owner: wjgvsmhxtynijy
--

CREATE TABLE "User" (
    "ID" integer NOT NULL,
    "Name" text NOT NULL,
    "Username" text,
    "Email" text NOT NULL,
    "Handicap" numeric(3,2),
    "Gender" text NOT NULL
);


ALTER TABLE "User" OWNER TO wjgvsmhxtynijy;

--
-- Name: User_ID_seq; Type: SEQUENCE; Schema: public; Owner: wjgvsmhxtynijy
--

CREATE SEQUENCE "User_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "User_ID_seq" OWNER TO wjgvsmhxtynijy;

--
-- Name: User_ID_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER SEQUENCE "User_ID_seq" OWNED BY "User"."ID";


--
-- Name: ID; Type: DEFAULT; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER TABLE ONLY "Club" ALTER COLUMN "ID" SET DEFAULT nextval('"Club_ID_seq"'::regclass);


--
-- Name: ID; Type: DEFAULT; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER TABLE ONLY "Course" ALTER COLUMN "ID" SET DEFAULT nextval('"Course_ID_seq"'::regclass);


--
-- Name: ID; Type: DEFAULT; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER TABLE ONLY "Round" ALTER COLUMN "ID" SET DEFAULT nextval('"Round_ID_seq"'::regclass);


--
-- Name: ID; Type: DEFAULT; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER TABLE ONLY "RoundCourse" ALTER COLUMN "ID" SET DEFAULT nextval('"RoundCourses_ID_seq"'::regclass);


--
-- Name: ID; Type: DEFAULT; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER TABLE ONLY "RoundUser" ALTER COLUMN "ID" SET DEFAULT nextval('"Score_ID_seq"'::regclass);


--
-- Name: ID; Type: DEFAULT; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER TABLE ONLY "Tee" ALTER COLUMN "ID" SET DEFAULT nextval('"Tee_ID_seq"'::regclass);


--
-- Name: ID; Type: DEFAULT; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER TABLE ONLY "User" ALTER COLUMN "ID" SET DEFAULT nextval('"User_ID_seq"'::regclass);


--
-- Name: Club_PK; Type: CONSTRAINT; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER TABLE ONLY "Club"
    ADD CONSTRAINT "Club_PK" PRIMARY KEY ("ID");


--
-- Name: Club_UNIQUE_Name; Type: CONSTRAINT; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER TABLE ONLY "Club"
    ADD CONSTRAINT "Club_UNIQUE_Name" UNIQUE ("Name");


--
-- Name: Club_UNIQUE_ShortName; Type: CONSTRAINT; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER TABLE ONLY "Club"
    ADD CONSTRAINT "Club_UNIQUE_ShortName" UNIQUE ("ShortName");


--
-- Name: CourseHole_PK; Type: CONSTRAINT; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER TABLE ONLY "CourseHole"
    ADD CONSTRAINT "CourseHole_PK" PRIMARY KEY ("CourseID", "Number");


--
-- Name: Course_PK; Type: CONSTRAINT; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER TABLE ONLY "Course"
    ADD CONSTRAINT "Course_PK" PRIMARY KEY ("ID");


--
-- Name: RoundCourse_PK; Type: CONSTRAINT; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER TABLE ONLY "RoundCourse"
    ADD CONSTRAINT "RoundCourse_PK" PRIMARY KEY ("ID");


--
-- Name: RoundCourse_UNIQUE; Type: CONSTRAINT; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER TABLE ONLY "RoundCourse"
    ADD CONSTRAINT "RoundCourse_UNIQUE" UNIQUE ("RoundID", "SequenceNum");


--
-- Name: RoundStrokes_PK; Type: CONSTRAINT; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER TABLE ONLY "RoundStrokes"
    ADD CONSTRAINT "RoundStrokes_PK" PRIMARY KEY ("UserID", "RoundCourseID", "HoleNumber");


--
-- Name: RoundUser_PK; Type: CONSTRAINT; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER TABLE ONLY "RoundUser"
    ADD CONSTRAINT "RoundUser_PK" PRIMARY KEY ("ID");


--
-- Name: RoundUser_UNIQUE; Type: CONSTRAINT; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER TABLE ONLY "RoundUser"
    ADD CONSTRAINT "RoundUser_UNIQUE" UNIQUE ("UserID", "RoundID");


--
-- Name: Round_PK; Type: CONSTRAINT; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER TABLE ONLY "Round"
    ADD CONSTRAINT "Round_PK" PRIMARY KEY ("ID");


--
-- Name: TeeHole_PK; Type: CONSTRAINT; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER TABLE ONLY "TeeHole"
    ADD CONSTRAINT "TeeHole_PK" PRIMARY KEY ("TeeID", "Number");


--
-- Name: TeeHole_UNIQUE; Type: CONSTRAINT; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER TABLE ONLY "TeeHole"
    ADD CONSTRAINT "TeeHole_UNIQUE" UNIQUE ("TeeID", "Number");


--
-- Name: Tee_PK; Type: CONSTRAINT; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER TABLE ONLY "Tee"
    ADD CONSTRAINT "Tee_PK" PRIMARY KEY ("ID");


--
-- Name: Tee_UNIQUE; Type: CONSTRAINT; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER TABLE ONLY "Tee"
    ADD CONSTRAINT "Tee_UNIQUE" UNIQUE ("CourseID", "Name");


--
-- Name: User_PK; Type: CONSTRAINT; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER TABLE ONLY "User"
    ADD CONSTRAINT "User_PK" PRIMARY KEY ("ID");


--
-- Name: User_UNIQUE; Type: CONSTRAINT; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER TABLE ONLY "User"
    ADD CONSTRAINT "User_UNIQUE" UNIQUE ("Username");


--
-- Name: fki_RoundCourses_FK_TeeID; Type: INDEX; Schema: public; Owner: wjgvsmhxtynijy
--

CREATE INDEX "fki_RoundCourses_FK_TeeID" ON "RoundCourse" USING btree ("TeeID");


--
-- Name: CourseHole_FK_CourseID; Type: FK CONSTRAINT; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER TABLE ONLY "CourseHole"
    ADD CONSTRAINT "CourseHole_FK_CourseID" FOREIGN KEY ("CourseID") REFERENCES "Course"("ID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Course_FK_ClubID; Type: FK CONSTRAINT; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER TABLE ONLY "Course"
    ADD CONSTRAINT "Course_FK_ClubID" FOREIGN KEY ("ClubID") REFERENCES "Club"("ID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: RoundCourse_FK_CourseID; Type: FK CONSTRAINT; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER TABLE ONLY "RoundCourse"
    ADD CONSTRAINT "RoundCourse_FK_CourseID" FOREIGN KEY ("CourseID") REFERENCES "Course"("ID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: RoundCourse_FK_RoundID; Type: FK CONSTRAINT; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER TABLE ONLY "RoundCourse"
    ADD CONSTRAINT "RoundCourse_FK_RoundID" FOREIGN KEY ("RoundID") REFERENCES "Round"("ID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: RoundCourse_FK_TeeID; Type: FK CONSTRAINT; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER TABLE ONLY "RoundCourse"
    ADD CONSTRAINT "RoundCourse_FK_TeeID" FOREIGN KEY ("TeeID") REFERENCES "Tee"("ID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: RoundStrokes_FK_RoundCourseID; Type: FK CONSTRAINT; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER TABLE ONLY "RoundStrokes"
    ADD CONSTRAINT "RoundStrokes_FK_RoundCourseID" FOREIGN KEY ("RoundCourseID") REFERENCES "RoundCourse"("ID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: RoundStrokes_FK_UserID; Type: FK CONSTRAINT; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER TABLE ONLY "RoundStrokes"
    ADD CONSTRAINT "RoundStrokes_FK_UserID" FOREIGN KEY ("UserID") REFERENCES "User"("ID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: RoundUser_FK_RoundID; Type: FK CONSTRAINT; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER TABLE ONLY "RoundUser"
    ADD CONSTRAINT "RoundUser_FK_RoundID" FOREIGN KEY ("RoundID") REFERENCES "Round"("ID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: RoundUser_FK_UserID; Type: FK CONSTRAINT; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER TABLE ONLY "RoundUser"
    ADD CONSTRAINT "RoundUser_FK_UserID" FOREIGN KEY ("UserID") REFERENCES "User"("ID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Round_FK_ClubID; Type: FK CONSTRAINT; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER TABLE ONLY "Round"
    ADD CONSTRAINT "Round_FK_ClubID" FOREIGN KEY ("ClubID") REFERENCES "Club"("ID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: TeeHole_FK_TeeID; Type: FK CONSTRAINT; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER TABLE ONLY "TeeHole"
    ADD CONSTRAINT "TeeHole_FK_TeeID" FOREIGN KEY ("TeeID") REFERENCES "Tee"("ID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Tee_FK_CourseID; Type: FK CONSTRAINT; Schema: public; Owner: wjgvsmhxtynijy
--

ALTER TABLE ONLY "Tee"
    ADD CONSTRAINT "Tee_FK_CourseID" FOREIGN KEY ("CourseID") REFERENCES "Course"("ID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: public; Type: ACL; Schema: -; Owner: wjgvsmhxtynijy
--

REVOKE ALL ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON SCHEMA public FROM wjgvsmhxtynijy;
GRANT ALL ON SCHEMA public TO wjgvsmhxtynijy;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO PUBLIC;


--
-- PostgreSQL database dump complete
--

