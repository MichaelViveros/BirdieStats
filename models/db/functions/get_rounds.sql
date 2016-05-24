-- Function: public.get_rounds(text)
--
-- Sample function call:
-- SELECT * FROM get_rounds('Michael');

-- DROP FUNCTION public.get_rounds(text);

CREATE OR REPLACE FUNCTION public.get_rounds(IN user_name text)
  RETURNS TABLE(round_id integer, round_date date, club text, round_course_id integer, course text, tees text, player text, hole integer, yards integer, par integer, strokes integer) AS
$BODY$

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
$BODY$
  LANGUAGE sql STABLE STRICT