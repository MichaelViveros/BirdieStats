-- Function: public.insert_rounds(date, text, text[], text[], text[], integer[], integer[])
--
-- Sample function call:
--
-- SELECT insert_rounds(
-- 	CURRENT_DATE, 
-- 	'Chedoke', 
-- 	array['Michael Viveros', 'Roman Viveros'], 
-- 	array['Martin','Beddoe'], 
-- 	array['Blue','White'], 
-- 	array[ [1,2,3,4], [1,2,3,4] ],
-- 	array[ [ [3,3,5,7], [5,3,7,2] ], [ [4,4,6,4], [2,6,3,3] ] ]
-- );


--DROP FUNCTION public.insert_rounds(date, text, text[], text[], text[], integer[], integer[]);

CREATE OR REPLACE FUNCTION public.insert_rounds(
    round_date date,
    club text,
    user_names text[],
    courses text[],
    tees text[],
    holes integer[],
    strokes integer[])
  RETURNS boolean AS
$BODY$
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

$BODY$
  LANGUAGE plpgsql VOLATILE