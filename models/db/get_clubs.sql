-- Function: public.get_clubs(text)
--
-- Sample function call:
-- SELECT * FROM get_clubs();

-- DROP FUNCTION public.get_clubs();

CREATE OR REPLACE FUNCTION public.get_clubs()
  RETURNS TABLE(club_id integer, club text, course_id integer, course text, tee_id integer, tees text) AS
$BODY$

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

$BODY$
  LANGUAGE sql STABLE STRICT