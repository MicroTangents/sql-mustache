# SQL Mustache

This work was inspired by the [Mustache](https://mustache.github.io/) templating system by Chris Wanstrath and other contributors which in turn was inspired by [ctemplate](http://goog-ctemplate.sourceforge.net/)).

This particular project is built to work with SQL Server 2016 or higher.

This is a "logic-less" simple templating system that allows templates to be stored in whatever manner makes sense (tables, in code, config files, or whatever).

It can be used for pretty much anything that demands a template.

This implementation is opinionated about formatting because it is important to maintain strict formatting with templates for message and even dynamic code generation.

Because of this, the templates produced will need to be sensitive to how the tags are layed out within the template.

The renderer assumes that if you put whitespace in the template that it was deliberate and every effort is made to respect all formatting.

## Detailed Discussion

For a detailed exploration around the construction of this system see the article: [SQL Mustache: How to Create a Logicless Template Renderer](https://microtangents.com/sql-mustache:-how-to-create-a-logicless-template-renderer/).

## To Install

``` text
1. Clone the repo
2. Edit install.ini adding your ServerName and DatabaseName
3. Run install.cmd from the project folder
```

## Why You Might Use a Mustache Template

Use Mustache when you want to craft a data driven readable string that keeps formatting intact without a complex set of logic.

In many cases you are limited only by your imagination. Here are some examples.

### Email Messaging system

Perhaps your application needs to produce email messages, you could fairly easily craft a templating system that you could then expose to end user authors.

Those authors could then use any variables translated to keys (or tags) within an email message template.

Example:

``` sql
DECLARE @msgTpl NVARCHAR(max) = N'Dear {{name}},

Thank you for being such a loyal customer, in {{year}} to date the products you''ve purchased are:
{{#products}} * {{product}}
{{/products}}
Thank you for your support!

The Management';

DECLARE @json NVARCHAR(max) = N'{
  "name":"Jack",
  "products":[
    {"product":"Widget Burner Premium"},
    {"product":"Book Builder Deluxe"},
    {"product":"Magic AI 99.97.765"}
  ]
}';

PRINT mustache.s_render(@msgTpl, @json);
```

### Machine Messaging system

It's often necessary to construct messages for queueing systems that take many shapes.

In SQL this typically takes the shape of queries and string concatenation for XML, JSON, or some other proprietary message structure.

Which is more readable?

This:

``` sql
DECLARE @m NVARCHAR(max) = N'<message>
    <id>' + FORMAT(@id, 'G') + N'</id>
    <user>' + COALESCE(NULLIF(@user, ''), N'unknown') + N'</user>
    <dto>' + COALESCE(@dto, GETUTCDATE()) + N'</dto>
</message>'
```

Or this:

``` sql
DECLARE @m NVARCHAR(max) = N'<message>
    <id>{{id}}</id>
    <user>{{user}}</user>
    <dto>{{dto}}</dto>
</message>'
```

### Even Dynamic Code can be Templated Out

Whether you are a proponent of dynamics or not regardless of the technology that is being used, it's often necessary to engage in some kind of evaluated string.

I don't know about you, but I like to at least be able to read the code and that includes the formatting of the text within the template.

``` sql
DECLARE @sqlText NVARCHAR(max) = N'
    SELECT s.id {{fieldList}}
    FROM #_tbl_stuff s
    {{#where}}{{criteria}}{{/where}}
';
```

Maybe you think that's ugly, but it's far prettier than what often ends up as the alternative.

## Simple Usage - Hello World

``` sql
PRINT mustache.s_render(
        N'Hello {{locale}}'
        , N'{"locale":"World"}'
);
```

Outputs:

``` text
Hello World
```

Here's the [Demo](https://mustache.github.io/#demo) example (as formatted):

``` sql
DECLARE @template NVARCHAR(max) = N'<h1>{{header}}</h1>
{{#bug}}
{{/bug}}

{{#items}}
  {{#first}}
    <li><strong>{{name}}</strong></li>
  {{/first}}
  {{#link}}
    <li><a href="{{url}}">{{name}}</a></li>
  {{/link}}
{{/items}}

{{#empty}}
  <p>The list is empty.</p>
{{/empty}}';

DECLARE @json NVARCHAR(max) = N'{
  "header": "Colors",
  "items": [
      {"name": "red", "first": true, "url": "#Red"},
      {"name": "green", "link": true, "url": "#Green"},
      {"name": "blue", "link": true, "url": "#Blue"}
  ],
  "empty": false
}';

PRINT mustache.s_render(@template, @json);
```

Which will output:

``` html
<h1>Colors</h1>



  
    <li><strong>red</strong></li>
  
  

  
  
    <li><a href="#Green">green</a></li>
  

  
  
    <li><a href="#Blue">blue</a></li>
  


```

Notice the liberal white space.  The demo itself removes all white space and formatting.

The SQL Mustache implementation will respect all white space and formatting.

While it is not necessary to worry much about formatting when dealing with HTML, it is very necessary when dealing with other use cases such as a plain text email template, or a code template.

To get the appropriately formatted text (with a comment and unset variable added in), try this example:

``` sql
DECLARE @template NVARCHAR(max) = N'<h1>{{header}}</h1>
{{#bug}}
{{/bug}}

<ul>
{{#items}}  {{#first}}<li><strong>{{name}}</strong></li>{{/first}}{{#link}}<li><a href="{{url}}">{{name}}</a></li>{{/link}}
{{/items}}</ul>

{{#empty}}  <p>The list is empty.</p>{{/empty}}

<p>{{notset}}{{! comment}}</p>
';

DECLARE @json NVARCHAR(max) = N'{
  "header": "Colors",
  "items": [
      {"name": "red", "first": true, "url": "#Red"},
      {"name": "green", "link": true, "url": "#Green"},
      {"name": "blue", "link": true, "url": "#Blue"}
  ],
  "empty": false
}';

PRINT mustache.s_render(@template, @json);
```

Compare this output with that above:

``` html
<h1>Colors</h1>


<ul>
    <li><strong>red</strong></li>
    <li><a href="#Green">green</a></li>
    <li><a href="#Blue">blue</a></li>
</ul>

  <p>The list is empty.</p>

<p></p>
```

## Supported Functionality

**Remember:** this implementation does NOT assume you are working with HTML and formatting for your template is **strictly respected**! Format your templates accordingly.

[&#10004;] Variables (Tags)

``` text
Template: A big animal = {{animal}}
Hash: { "animal" : "Elephant" }
Output: A big Animal = Elephant
```

[&#10004;] Unescaped Variables (Tags)

``` text
Template: <p>this is {{{html}}} this is encoded {{html}}<p>
Hash: {"html":"<b>bold</b>"}
Output: <p>this is <b>bold</b> this is encoded &lt;b&gt;bold&lt;/b&gt;<p>
```

[&#10004;] Comments

``` text
Template: |{{! this is a comment }}|
Hash: {}
Output: ||
```

[&#10004;] Sections

``` text
Template: {{#showMe}}Shown{{/showMe}}{{#hideMe}}Hidden{{/hideMe}}
Hash: { "showme" : true, "hideMe" : false }
Output: Shown
```

[&#10004;] Nested Sections

``` text
Template: {{#outer}}{{#inner}}{{tag}}{{/inner}}{{/outer}}
Hash: { "outer": [{"inner": {"tag": 1}}, {"inner": {"tag": 2}}, {"inner": {"tag": 3}} ]}
Output: 123
```

[&#10004;] Conditional Sections

``` text
Template: {{#people}} <b>{{person}}</b> {{/people}} {{^people}} No people {{/people}}
Hash: { "people": [] }
Output:   No people
```

[&#10004;] Conditional Sections - false

``` text
Template: {{#people}} <b>{{person}}</b> {{/people}} {{^people}} No people {{/people}}
Hash: { "people": false }
Output:   No people
```

## Un-Supported Functionality

[❌] Partials - essentially the ability to include templates

[❌] Lambdas - temporary functions compiled and executed at run time

[❌] Set Delimiter - the ability to set something other than curly's as the tag notation delimiters

[❌] Error on Missing Tag in Object - missing tags are simply discarded and replaced with an empty string

## Meta

* Code: git clone <https://github.com/microtangents/sql-mustache>
* Home: <https://microtangents.com>
* Bugs: <https://github.com/microtangents/sql-mustache/issues>
* Repo: <https://github.com/microtangents/sql-mustache>
* JSDocs: [Source Documentation](https://htmlpreview.github.io/?https://github.com/MicroTangents/sql-mustache/blob/master/docs/index.html)
