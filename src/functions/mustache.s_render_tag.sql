SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
/**
Processes simple tags for a mustache template

@module mustache/s_render_tag
@see module:mustache/s_render

@param {nvarchar(max)} @template - the mustache template to render
@param {nvarchar(128)} @tag - the name of the placeholder tag to render (substitute)
@param {nvarchar(max)} @value - the value to subsitute for the placeholder tag 
@returns {nvarchar(max)} the @template with any @tag's replaced with @value

@date 2020-07-10
@author James Kelly

@example
this is an example
*/
CREATE OR ALTER FUNCTION mustache.s_render_tag
(
	@template NVARCHAR(max),
	@tag NVARCHAR(128),
	@value NVARCHAR(max)
)
RETURNS NVARCHAR(max)
AS
BEGIN
	DECLARE @doc		NVARCHAR(max)	= @template;
	DECLARE @docLen		INT				= LEN(@doc);
	DECLARE @emptyCnt	INT				= 0;

	--replace with unescaped html
	SET @doc = REPLACE(@doc, CONCAT(N'{{{', @tag, N'}}}'), @value);

	--replace with unescaped html - alternate syntax
	SET @doc = REPLACE(@doc, CONCAT(N'{{& ', @tag, N'}}'), @value);

	--replace with unescaped html - alternate syntax - lenient
	SET @doc = REPLACE(@doc, CONCAT(N'{{&', @tag, N'}}'), @value);

	--replace with escaped html
	SET @doc = REPLACE(@doc, CONCAT(N'{{', @tag, N'}}'), CONVERT(NVARCHAR(max), (SELECT @value [*] FOR XML PATH(''))));

	RETURN @doc;
END;