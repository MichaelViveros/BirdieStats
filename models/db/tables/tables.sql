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
-- Name: birdie-stats; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA "birdie-stats";


ALTER SCHEMA "birdie-stats" OWNER TO postgres;

SET search_path = "birdie-stats", pg_catalog;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: Club; Type: TABLE; Schema: birdie-stats; Owner: postgres
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
-- Name: Club_ID_seq; Type: SEQUENCE; Schema: birdie-stats; Owner: postgres
--

CREATE SEQUENCE "Club_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "Club_ID_seq" OWNER TO postgres;

--
-- Name: Club_ID_seq; Type: SEQUENCE OWNED BY; Schema: birdie-stats; Owner: postgres
--

ALTER SEQUENCE "Club_ID_seq" OWNED BY "Club"."ID";


--
-- Name: Course; Type: TABLE; Schema: birdie-stats; Owner: postgres
--

CREATE TABLE "Course" (
    "ID" integer NOT NULL,
    "Name" text,
    "ClubID" integer NOT NULL
);


ALTER TABLE "Course" OWNER TO postgres;

--
-- Name: CourseHole; Type: TABLE; Schema: birdie-stats; Owner: postgres
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
-- Name: Course_ID_seq; Type: SEQUENCE; Schema: birdie-stats; Owner: postgres
--

CREATE SEQUENCE "Course_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "Course_ID_seq" OWNER TO postgres;

--
-- Name: Course_ID_seq; Type: SEQUENCE OWNED BY; Schema: birdie-stats; Owner: postgres
--

ALTER SEQUENCE "Course_ID_seq" OWNED BY "Course"."ID";


--
-- Name: Round; Type: TABLE; Schema: birdie-stats; Owner: postgres
--

CREATE TABLE "Round" (
    "ID" integer NOT NULL,
    "Date" date NOT NULL,
    "ClubID" integer NOT NULL
);


ALTER TABLE "Round" OWNER TO postgres;

--
-- Name: RoundCourse; Type: TABLE; Schema: birdie-stats; Owner: postgres
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
-- Name: RoundCourses_ID_seq; Type: SEQUENCE; Schema: birdie-stats; Owner: postgres
--

CREATE SEQUENCE "RoundCourses_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "RoundCourses_ID_seq" OWNER TO postgres;

--
-- Name: RoundCourses_ID_seq; Type: SEQUENCE OWNED BY; Schema: birdie-stats; Owner: postgres
--

ALTER SEQUENCE "RoundCourses_ID_seq" OWNED BY "RoundCourse"."ID";


--
-- Name: RoundStrokes; Type: TABLE; Schema: birdie-stats; Owner: postgres
--

CREATE TABLE "RoundStrokes" (
    "UserID" integer NOT NULL,
    "HoleNumber" integer NOT NULL,
    "Strokes" integer NOT NULL,
    "RoundCourseID" integer NOT NULL
);


ALTER TABLE "RoundStrokes" OWNER TO postgres;

--
-- Name: RoundUser; Type: TABLE; Schema: birdie-stats; Owner: postgres
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
-- Name: Round_ID_seq; Type: SEQUENCE; Schema: birdie-stats; Owner: postgres
--

CREATE SEQUENCE "Round_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "Round_ID_seq" OWNER TO postgres;

--
-- Name: Round_ID_seq; Type: SEQUENCE OWNED BY; Schema: birdie-stats; Owner: postgres
--

ALTER SEQUENCE "Round_ID_seq" OWNED BY "Round"."ID";


--
-- Name: Score_ID_seq; Type: SEQUENCE; Schema: birdie-stats; Owner: postgres
--

CREATE SEQUENCE "Score_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "Score_ID_seq" OWNER TO postgres;

--
-- Name: Score_ID_seq; Type: SEQUENCE OWNED BY; Schema: birdie-stats; Owner: postgres
--

ALTER SEQUENCE "Score_ID_seq" OWNED BY "RoundUser"."ID";


--
-- Name: Tee; Type: TABLE; Schema: birdie-stats; Owner: postgres
--

CREATE TABLE "Tee" (
    "ID" integer NOT NULL,
    "CourseID" integer NOT NULL,
    "Name" text,
    "Slope" double precision,
    "Rating" numeric(3,1),
    "LadiesSlope" double precision,
    "LadiesRating" numeric(2,1),
    "TotalYardage" integer NOT NULL
);


ALTER TABLE "Tee" OWNER TO postgres;

--
-- Name: TeeHole; Type: TABLE; Schema: birdie-stats; Owner: postgres
--

CREATE TABLE "TeeHole" (
    "TeeID" integer NOT NULL,
    "Number" integer NOT NULL,
    "Yards" integer NOT NULL
);


ALTER TABLE "TeeHole" OWNER TO postgres;

--
-- Name: Tee_ID_seq; Type: SEQUENCE; Schema: birdie-stats; Owner: postgres
--

CREATE SEQUENCE "Tee_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "Tee_ID_seq" OWNER TO postgres;

--
-- Name: Tee_ID_seq; Type: SEQUENCE OWNED BY; Schema: birdie-stats; Owner: postgres
--

ALTER SEQUENCE "Tee_ID_seq" OWNED BY "Tee"."ID";


--
-- Name: User; Type: TABLE; Schema: birdie-stats; Owner: postgres
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
-- Name: User_ID_seq; Type: SEQUENCE; Schema: birdie-stats; Owner: postgres
--

CREATE SEQUENCE "User_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE "User_ID_seq" OWNER TO postgres;

--
-- Name: User_ID_seq; Type: SEQUENCE OWNED BY; Schema: birdie-stats; Owner: postgres
--

ALTER SEQUENCE "User_ID_seq" OWNED BY "User"."ID";


--
-- Name: ID; Type: DEFAULT; Schema: birdie-stats; Owner: postgres
--

ALTER TABLE ONLY "Club" ALTER COLUMN "ID" SET DEFAULT nextval('"Club_ID_seq"'::regclass);


--
-- Name: ID; Type: DEFAULT; Schema: birdie-stats; Owner: postgres
--

ALTER TABLE ONLY "Course" ALTER COLUMN "ID" SET DEFAULT nextval('"Course_ID_seq"'::regclass);


--
-- Name: ID; Type: DEFAULT; Schema: birdie-stats; Owner: postgres
--

ALTER TABLE ONLY "Round" ALTER COLUMN "ID" SET DEFAULT nextval('"Round_ID_seq"'::regclass);


--
-- Name: ID; Type: DEFAULT; Schema: birdie-stats; Owner: postgres
--

ALTER TABLE ONLY "RoundCourse" ALTER COLUMN "ID" SET DEFAULT nextval('"RoundCourses_ID_seq"'::regclass);


--
-- Name: ID; Type: DEFAULT; Schema: birdie-stats; Owner: postgres
--

ALTER TABLE ONLY "RoundUser" ALTER COLUMN "ID" SET DEFAULT nextval('"Score_ID_seq"'::regclass);


--
-- Name: ID; Type: DEFAULT; Schema: birdie-stats; Owner: postgres
--

ALTER TABLE ONLY "Tee" ALTER COLUMN "ID" SET DEFAULT nextval('"Tee_ID_seq"'::regclass);


--
-- Name: ID; Type: DEFAULT; Schema: birdie-stats; Owner: postgres
--

ALTER TABLE ONLY "User" ALTER COLUMN "ID" SET DEFAULT nextval('"User_ID_seq"'::regclass);


--
-- Data for Name: Club; Type: TABLE DATA; Schema: birdie-stats; Owner: postgres
--

COPY "Club" ("ID", "Name", "ShortName", "Address", "City", "Province", "Country") FROM stdin;
1	Chedoke Golf Club	Chedoke	563 Aberdeen Avenue	Hamilton	ON	Canada
\.


--
-- Name: Club_ID_seq; Type: SEQUENCE SET; Schema: birdie-stats; Owner: postgres
--

SELECT pg_catalog.setval('"Club_ID_seq"', 1, true);


--
-- Data for Name: Course; Type: TABLE DATA; Schema: birdie-stats; Owner: postgres
--

COPY "Course" ("ID", "Name", "ClubID") FROM stdin;
1	Beddoe	1
2	Martin	1
\.


--
-- Data for Name: CourseHole; Type: TABLE DATA; Schema: birdie-stats; Owner: postgres
--

COPY "CourseHole" ("CourseID", "Number", "Par", "Handicap", "LadiesPar", "LadiesHandicap") FROM stdin;
1	1	4	9	4	\N
1	2	4	3	4	\N
1	3	3	15	3	\N
1	4	4	5	4	\N
1	5	5	11	5	\N
1	6	3	7	3	\N
1	7	4	1	5	\N
1	8	3	17	3	\N
1	9	5	13	5	\N
1	11	4	14	4	\N
1	12	4	12	4	\N
1	13	3	18	3	\N
1	14	5	8	5	\N
1	15	4	16	4	\N
1	16	4	10	4	\N
1	17	3	6	3	\N
1	18	4	4	4	\N
1	10	4	2	5	\N
2	1	4	13	4	\N
2	2	5	9	5	\N
2	3	3	15	4	\N
2	4	3	17	3	\N
2	5	4	11	4	\N
2	6	4	3	5	\N
2	7	5	7	5	\N
2	8	5	1	5	\N
2	9	4	5	4	\N
2	10	3	18	3	\N
2	11	4	4	4	\N
2	12	4	2	4	\N
2	13	4	10	4	\N
2	14	4	14	4	\N
2	15	4	6	4	\N
2	16	3	16	3	\N
2	17	3	8	3	\N
2	18	4	12	4	\N
\.


--
-- Name: Course_ID_seq; Type: SEQUENCE SET; Schema: birdie-stats; Owner: postgres
--

SELECT pg_catalog.setval('"Course_ID_seq"', 2, true);


--
-- Data for Name: Round; Type: TABLE DATA; Schema: birdie-stats; Owner: postgres
--

COPY "Round" ("ID", "Date", "ClubID") FROM stdin;
2	2016-03-22	1
4	2016-05-01	1
5	2016-05-01	1
6	2016-05-01	1
\.


--
-- Data for Name: RoundCourse; Type: TABLE DATA; Schema: birdie-stats; Owner: postgres
--

COPY "RoundCourse" ("ID", "RoundID", "CourseID", "SequenceNum", "TeeID") FROM stdin;
3	2	2	1	5
4	5	1	1	1
5	6	2	1	4
\.


--
-- Name: RoundCourses_ID_seq; Type: SEQUENCE SET; Schema: birdie-stats; Owner: postgres
--

SELECT pg_catalog.setval('"RoundCourses_ID_seq"', 5, true);


--
-- Data for Name: RoundStrokes; Type: TABLE DATA; Schema: birdie-stats; Owner: postgres
--

COPY "RoundStrokes" ("UserID", "HoleNumber", "Strokes", "RoundCourseID") FROM stdin;
1	1	6	3
1	2	5	3
1	3	4	3
2	1	4	3
2	2	6	3
2	3	3	3
1	1	4	4
1	2	2	4
1	3	5	4
2	1	4	5
2	2	2	5
2	3	5	5
2	4	6	5
2	5	2	5
\.


--
-- Data for Name: RoundUser; Type: TABLE DATA; Schema: birdie-stats; Owner: postgres
--

COPY "RoundUser" ("ID", "UserID", "RoundID", "TotalStrokes", "TotalHoles") FROM stdin;
1	1	2	15	3
2	2	2	13	3
3	1	5	\N	\N
4	2	6	\N	\N
\.


--
-- Name: Round_ID_seq; Type: SEQUENCE SET; Schema: birdie-stats; Owner: postgres
--

SELECT pg_catalog.setval('"Round_ID_seq"', 6, true);


--
-- Name: Score_ID_seq; Type: SEQUENCE SET; Schema: birdie-stats; Owner: postgres
--

SELECT pg_catalog.setval('"Score_ID_seq"', 4, true);


--
-- Data for Name: Tee; Type: TABLE DATA; Schema: birdie-stats; Owner: postgres
--

COPY "Tee" ("ID", "CourseID", "Name", "Slope", "Rating", "LadiesSlope", "LadiesRating", "TotalYardage") FROM stdin;
1	1	Blue	119	69.2	\N	\N	6084
3	1	White	116	67.9	\N	\N	5773
4	1	Red	113	66.3	\N	\N	5464
5	2	Blue	110	67.1	\N	\N	5745
6	2	Red	108	66.0	\N	\N	5505
\.


--
-- Data for Name: TeeHole; Type: TABLE DATA; Schema: birdie-stats; Owner: postgres
--

COPY "TeeHole" ("TeeID", "Number", "Yards") FROM stdin;
1	1	342
1	2	385
1	3	176
1	4	357
1	5	459
1	6	206
1	7	441
1	8	138
1	9	444
1	10	454
1	11	370
1	12	352
1	13	172
1	14	516
1	15	274
1	16	356
1	17	202
1	18	430
3	1	322
3	2	355
3	3	157
3	4	353
3	5	443
3	6	197
3	7	426
3	8	130
3	9	432
3	10	436
3	11	345
3	12	340
3	13	165
3	14	492
3	15	253
3	16	340
3	17	187
3	18	400
4	1	282
4	2	343
4	3	122
4	4	353
4	5	427
4	6	190
4	7	426
4	8	122
4	9	414
4	10	428
4	11	345
4	12	340
4	13	153
4	14	482
4	15	207
4	16	290
4	17	176
4	18	364
5	1	326
5	9	315
5	2	491
5	3	260
5	4	172
5	5	353
5	6	424
5	7	498
5	8	485
5	10	150
5	11	370
5	12	420
5	13	271
5	14	252
5	15	357
5	16	127
5	17	215
5	18	259
6	1	291
6	2	478
6	3	250
6	4	165
6	5	341
6	6	411
6	7	493
6	8	480
6	9	303
6	10	135
6	11	358
6	12	395
6	13	258
6	14	240
6	15	350
6	16	120
6	17	193
6	18	244
\.


--
-- Name: Tee_ID_seq; Type: SEQUENCE SET; Schema: birdie-stats; Owner: postgres
--

SELECT pg_catalog.setval('"Tee_ID_seq"', 6, true);


--
-- Data for Name: User; Type: TABLE DATA; Schema: birdie-stats; Owner: postgres
--

COPY "User" ("ID", "Name", "Username", "Email", "Handicap", "Gender") FROM stdin;
1	Michael Viveros	mikevman7	michaelviveros@gmail.com	\N	Male
2	Roman Viveros	rviveros	rviveros@ms.mcmaster.ca	\N	Male
\.


--
-- Name: User_ID_seq; Type: SEQUENCE SET; Schema: birdie-stats; Owner: postgres
--

SELECT pg_catalog.setval('"User_ID_seq"', 2, true);


--
-- Name: Club_PK; Type: CONSTRAINT; Schema: birdie-stats; Owner: postgres
--

ALTER TABLE ONLY "Club"
    ADD CONSTRAINT "Club_PK" PRIMARY KEY ("ID");


--
-- Name: Club_UNIQUE_Name; Type: CONSTRAINT; Schema: birdie-stats; Owner: postgres
--

ALTER TABLE ONLY "Club"
    ADD CONSTRAINT "Club_UNIQUE_Name" UNIQUE ("Name");


--
-- Name: Club_UNIQUE_ShortName; Type: CONSTRAINT; Schema: birdie-stats; Owner: postgres
--

ALTER TABLE ONLY "Club"
    ADD CONSTRAINT "Club_UNIQUE_ShortName" UNIQUE ("ShortName");


--
-- Name: CourseHole_PK; Type: CONSTRAINT; Schema: birdie-stats; Owner: postgres
--

ALTER TABLE ONLY "CourseHole"
    ADD CONSTRAINT "CourseHole_PK" PRIMARY KEY ("CourseID", "Number");


--
-- Name: Course_PK; Type: CONSTRAINT; Schema: birdie-stats; Owner: postgres
--

ALTER TABLE ONLY "Course"
    ADD CONSTRAINT "Course_PK" PRIMARY KEY ("ID");


--
-- Name: RoundCourse_PK; Type: CONSTRAINT; Schema: birdie-stats; Owner: postgres
--

ALTER TABLE ONLY "RoundCourse"
    ADD CONSTRAINT "RoundCourse_PK" PRIMARY KEY ("ID");


--
-- Name: RoundCourse_UNIQUE; Type: CONSTRAINT; Schema: birdie-stats; Owner: postgres
--

ALTER TABLE ONLY "RoundCourse"
    ADD CONSTRAINT "RoundCourse_UNIQUE" UNIQUE ("RoundID", "SequenceNum");


--
-- Name: RoundStrokes_PK; Type: CONSTRAINT; Schema: birdie-stats; Owner: postgres
--

ALTER TABLE ONLY "RoundStrokes"
    ADD CONSTRAINT "RoundStrokes_PK" PRIMARY KEY ("UserID", "RoundCourseID", "HoleNumber");


--
-- Name: RoundUser_PK; Type: CONSTRAINT; Schema: birdie-stats; Owner: postgres
--

ALTER TABLE ONLY "RoundUser"
    ADD CONSTRAINT "RoundUser_PK" PRIMARY KEY ("ID");


--
-- Name: RoundUser_UNIQUE; Type: CONSTRAINT; Schema: birdie-stats; Owner: postgres
--

ALTER TABLE ONLY "RoundUser"
    ADD CONSTRAINT "RoundUser_UNIQUE" UNIQUE ("UserID", "RoundID");


--
-- Name: Round_PK; Type: CONSTRAINT; Schema: birdie-stats; Owner: postgres
--

ALTER TABLE ONLY "Round"
    ADD CONSTRAINT "Round_PK" PRIMARY KEY ("ID");


--
-- Name: TeeHole_PK; Type: CONSTRAINT; Schema: birdie-stats; Owner: postgres
--

ALTER TABLE ONLY "TeeHole"
    ADD CONSTRAINT "TeeHole_PK" PRIMARY KEY ("TeeID", "Number");


--
-- Name: TeeHole_UNIQUE; Type: CONSTRAINT; Schema: birdie-stats; Owner: postgres
--

ALTER TABLE ONLY "TeeHole"
    ADD CONSTRAINT "TeeHole_UNIQUE" UNIQUE ("TeeID", "Number");


--
-- Name: Tee_PK; Type: CONSTRAINT; Schema: birdie-stats; Owner: postgres
--

ALTER TABLE ONLY "Tee"
    ADD CONSTRAINT "Tee_PK" PRIMARY KEY ("ID");


--
-- Name: Tee_UNIQUE; Type: CONSTRAINT; Schema: birdie-stats; Owner: postgres
--

ALTER TABLE ONLY "Tee"
    ADD CONSTRAINT "Tee_UNIQUE" UNIQUE ("CourseID", "Name");


--
-- Name: User_PK; Type: CONSTRAINT; Schema: birdie-stats; Owner: postgres
--

ALTER TABLE ONLY "User"
    ADD CONSTRAINT "User_PK" PRIMARY KEY ("ID");


--
-- Name: User_UNIQUE; Type: CONSTRAINT; Schema: birdie-stats; Owner: postgres
--

ALTER TABLE ONLY "User"
    ADD CONSTRAINT "User_UNIQUE" UNIQUE ("Username");


--
-- Name: fki_RoundCourses_FK_TeeID; Type: INDEX; Schema: birdie-stats; Owner: postgres
--

CREATE INDEX "fki_RoundCourses_FK_TeeID" ON "RoundCourse" USING btree ("TeeID");


--
-- Name: CourseHole_FK_CourseID; Type: FK CONSTRAINT; Schema: birdie-stats; Owner: postgres
--

ALTER TABLE ONLY "CourseHole"
    ADD CONSTRAINT "CourseHole_FK_CourseID" FOREIGN KEY ("CourseID") REFERENCES "Course"("ID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Course_FK_ClubID; Type: FK CONSTRAINT; Schema: birdie-stats; Owner: postgres
--

ALTER TABLE ONLY "Course"
    ADD CONSTRAINT "Course_FK_ClubID" FOREIGN KEY ("ClubID") REFERENCES "Club"("ID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: RoundCourse_FK_CourseID; Type: FK CONSTRAINT; Schema: birdie-stats; Owner: postgres
--

ALTER TABLE ONLY "RoundCourse"
    ADD CONSTRAINT "RoundCourse_FK_CourseID" FOREIGN KEY ("CourseID") REFERENCES "Course"("ID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: RoundCourse_FK_RoundID; Type: FK CONSTRAINT; Schema: birdie-stats; Owner: postgres
--

ALTER TABLE ONLY "RoundCourse"
    ADD CONSTRAINT "RoundCourse_FK_RoundID" FOREIGN KEY ("RoundID") REFERENCES "Round"("ID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: RoundCourse_FK_TeeID; Type: FK CONSTRAINT; Schema: birdie-stats; Owner: postgres
--

ALTER TABLE ONLY "RoundCourse"
    ADD CONSTRAINT "RoundCourse_FK_TeeID" FOREIGN KEY ("TeeID") REFERENCES "Tee"("ID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: RoundStrokes_FK_RoundCourseID; Type: FK CONSTRAINT; Schema: birdie-stats; Owner: postgres
--

ALTER TABLE ONLY "RoundStrokes"
    ADD CONSTRAINT "RoundStrokes_FK_RoundCourseID" FOREIGN KEY ("RoundCourseID") REFERENCES "RoundCourse"("ID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: RoundStrokes_FK_UserID; Type: FK CONSTRAINT; Schema: birdie-stats; Owner: postgres
--

ALTER TABLE ONLY "RoundStrokes"
    ADD CONSTRAINT "RoundStrokes_FK_UserID" FOREIGN KEY ("UserID") REFERENCES "User"("ID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: RoundUser_FK_RoundID; Type: FK CONSTRAINT; Schema: birdie-stats; Owner: postgres
--

ALTER TABLE ONLY "RoundUser"
    ADD CONSTRAINT "RoundUser_FK_RoundID" FOREIGN KEY ("RoundID") REFERENCES "Round"("ID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: RoundUser_FK_UserID; Type: FK CONSTRAINT; Schema: birdie-stats; Owner: postgres
--

ALTER TABLE ONLY "RoundUser"
    ADD CONSTRAINT "RoundUser_FK_UserID" FOREIGN KEY ("UserID") REFERENCES "User"("ID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Round_FK_ClubID; Type: FK CONSTRAINT; Schema: birdie-stats; Owner: postgres
--

ALTER TABLE ONLY "Round"
    ADD CONSTRAINT "Round_FK_ClubID" FOREIGN KEY ("ClubID") REFERENCES "Club"("ID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: TeeHole_FK_TeeID; Type: FK CONSTRAINT; Schema: birdie-stats; Owner: postgres
--

ALTER TABLE ONLY "TeeHole"
    ADD CONSTRAINT "TeeHole_FK_TeeID" FOREIGN KEY ("TeeID") REFERENCES "Tee"("ID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: Tee_FK_CourseID; Type: FK CONSTRAINT; Schema: birdie-stats; Owner: postgres
--

ALTER TABLE ONLY "Tee"
    ADD CONSTRAINT "Tee_FK_CourseID" FOREIGN KEY ("CourseID") REFERENCES "Course"("ID") ON UPDATE CASCADE ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

