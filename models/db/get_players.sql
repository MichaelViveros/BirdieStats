-- Function: public.get_players(text)
--
-- Sample function call:
-- SELECT * FROM get_players();

-- DROP FUNCTION public.get_players();

CREATE OR REPLACE FUNCTION public.get_players()
  RETURNS TABLE(name text) AS
$BODY$

SELECT  
	user_info."Name"
FROM 
	"User" user_info
ORDER BY
	user_info."Name"

$BODY$
  LANGUAGE sql STABLE STRICT