SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
/**
Renders a mustache template given a supporting JSON object

@module mustache/s_render

@param {nvarchar(max)} @template - the mustache template to render
@param {nvarchar(max)} @json - the JSON object that will be used to render the sections and tags within the sub-document
@returns {nvarchar(max)} the @template rendered according to the {{mustache}} specification

@link
@see https://mustache.github.io/

@date 2020-07-10
@author James Kelly

@example
DECLARE @tpl NVARCHAR(max) = N'<h1>{{header}}</h1>
{{#bug}}
{{/bug}}

<ul>
{{#items}}{{#first}}<li><strong>{{name}}</strong></li>{{/first}}{{#link}}<li><a href="{{url}}">{{name}}</a></li>{{/link}}
{{/items}}</ul>

{{#empty}}  <p>The list is empty.</p>{{/empty}}

<p>{{notset}}{{! comment}}</p>
';

DECLARE @obj NVARCHAR(max)	= N'{
  "header": "Colors",
  "items": [
      {"name": "red", "first": true, "url": "#Red"},
      {"name": "green", "link": true, "url": "#Green"},
      {"name": "blue", "link": true, "url": "#Blue"}
  ],
  "empty": true
}';

PRINT mustache.s_render(@tpl, @obj);
*/
CREATE OR ALTER FUNCTION mustache.s_render
(
	@template NVARCHAR(max),
	@json NVARCHAR(max)
)
RETURNS NVARCHAR(max)
AS
BEGIN
	DECLARE @doc		NVARCHAR(max)	= @template;

	DECLARE @tblJson	TABLE (
		tag				NVARCHAR(256),
		val				NVARCHAR(max),
		valType			INT
	);

	INSERT INTO @tblJson (tag, val, valType)
	SELECT x.[key] tag, x.[value] val, x.[type] valType
	FROM OPENJSON(@json, N'$') x;

	SELECT @doc = mustache.s_render_section_array(@doc, s.tag, s.jsonSub)
	FROM (
		SELECT x.tag, x.val jsonSub
		FROM @tblJson x
		WHERE x.valType = 4
	) s;

	SELECT @doc = mustache.s_render_section_bool(@doc, s.variable, s.boolVal)
	FROM (
		SELECT x.tag variable, COALESCE(TRY_CONVERT(BIT, x.val), 0) boolVal
		FROM @tblJson x
		WHERE x.valType = 3
	) s;

	SELECT @doc = mustache.s_render_section_object(@doc, s.tag, s.jsonSub)
	FROM (
		SELECT x.tag, x.val jsonSub
		FROM @tblJson x
		WHERE x.valType = 5
	) s;

	SELECT @doc = mustache.s_render_tag(@doc, s.variable, s.val)
	FROM (
		SELECT x.tag variable, x.val
		FROM @tblJson x
		WHERE x.valType IN (1, 2)
	) s;

	SET @doc		= mustache.s_render_clean(@doc);

	RETURN @doc;
END;