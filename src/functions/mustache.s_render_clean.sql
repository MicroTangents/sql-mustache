SET ANSI_NULLS ON;
GO
SET QUOTED_IDENTIFIER ON;
GO
/**
Internal aspect - not typically called directly
Cleans up any remaining sections and comments that were not covered

@module mustache/s_render_clean
@see module:mustache/s_render

@param {nvarchar(max)} @template - the mustache template to render
@returns {nvarchar(max)} the @template with any @tag's replaced with @value

@date 2020-07-10
@author James Kelly
*/
CREATE OR ALTER FUNCTION mustache.s_render_clean
(
	@template NVARCHAR(max)
)
RETURNS NVARCHAR(max)
AS
BEGIN
	DECLARE @doc			NVARCHAR(max)	= @template;
	DECLARE @docLen			INT				= LEN(@doc);

	DECLARE @patOpen		NVARCHAR(256)	= N'%{{#%';
	DECLARE @patTagEnd		NVARCHAR(256)	= N'%}}%';

	DECLARE @idxTagStart	INT;
	DECLARE @idxTagLen		INT;

	DECLARE @tag			NVARCHAR(256);

	WHILE (@doc LIKE @patOpen)
	BEGIN
		SET @idxTagStart	= PATINDEX(@patOpen, @doc) + 3;
		SET @tag			= SUBSTRING(@doc, @idxTagStart, @docLen);
		SET @idxTagLen		= PATINDEX(@patTagEnd, @tag) - 1;
		SET @tag			= SUBSTRING(@doc, @idxTagStart, @idxTagLen);

		SET @doc			= mustache.s_render(@doc, CONCAT(N'{"', @tag, N'":false}'));
	END

	SET @patOpen			= N'%{{%';
	SET @patTagEnd			= N'%}}%';

	WHILE (@doc LIKE @patOpen)
	BEGIN
		SET @idxTagStart	= PATINDEX(@patOpen, @doc);
		SET @tag			= SUBSTRING(@doc, @idxTagStart, @docLen);
		--the patIndex already is inclusive of the first } so just add 1
		SET @idxTagLen		= PATINDEX(@patTagEnd, @tag) + 1;
		SET @tag			= SUBSTRING(@tag, 1, @idxTagLen);

		SET @doc			= REPLACE(@doc, @tag, N'');
	END

	RETURN @doc;
END;