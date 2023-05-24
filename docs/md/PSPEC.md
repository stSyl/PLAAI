<!-- template v. 2023-05-24T10:29-0400   -->
<!-- compatible with PSPEC v. 2023-05-21 -->
<style>
table {
  width: 100%;
}
</style>

# PSPEC - PLAAI Specification

Specification of a PLAAI pattern data structure.

<details>
  <summary>About ...</summary>
  <p>
  <table style="width:100%; font-size:75%;">
  <tr><td>Short Title: </td><td>Specification</td></tr>
  <tr><td>Contributors: </td><td>Boris STEIPE <boris.steipe@utoronto.ca></td></tr>
  <tr><td>Schema version: </td><td>v. 2023-05-21</td></tr>
  <tr><td>Last Update: </td><td>2023-05-23T15:21-0400</td></tr>
  <tr><td>Status: </td><td>dev</td></tr>
  <tr><td>Tree style: </td><td>show:FALSE; col:#EEEEFE; size:10; order:3</td></tr>
  </table>
  </p>
</details>

## Task:
This pattern is the specification of PLAAI pattern structures. It defines how PLAAI data is structured consistently to support generated views in different formats, ease of interconversion, machine readability, and human updates.

The PLAAI pattern specification.
================================

A PLAAI pattern structure is stored as a pairlist of keys and values in the JSON format. The conversion betwee JSON and .csv should be straightforward and lossless. Therefore, for simplicity, we do not use nested objects and where we need array-like data, we serialize them with semicolons.

Only two types of values are used: strings and Booleans. Similarly, we do not use NULL or NA values, but use an empty string where a value has not been set. Line breaks in PLAAI patterns are defined with a single newline character (ASCII: 10, 0x0A) and to avoid confusion, the carriage return character (ASCII: 13, 0x0D) is illegal in PLAAI patterns.

In this specification, all mandatory  values have been defined wrt. to the PSPEC pattern, since PSPEC itself is a valid PLAAI pattern.

Note that in its this JSON data is not valid JSON because it contains commants. It should validate after removal of the comment block.
*KEY: Mandatory. A five letter, uppercase, alphanumeric, mnemonic string. It must be unique among all PLAAI patterns and can be used as a primary key.

*KEY: Mandatory. Five characters from [A-Z0-9].
* TITLE: Mandatory. Describe the pattern in less than four words.
* SHORT: Mandatory. One or two words to be used as a tag in the reference tree.
* DEF: Mandatory. One sentence to define the pattern (used e.g. in hovertext).
* CONTRIB: Mandatory. Names and emails in Givenname FAMILYNAME <user@host> format, semicolon separated if more than one.
* VERSION: Mandatory. The pattern structure version, given as the date: v. YYYY-MM-DD.
* UPDATE: Mandatory. Last update as per ISO 8601: format(Sys.time(), '%Y-%m-%dT%H:%M%z'),
* STATUS: Mandatory. One of {stub, dev, public}. stub status requires all mandatorey fields to have values, this includes a task description. dev status requires keys for sources, exchangeables, and targets to be listed. public status is a worked out pattern, though it may not yet be in its final form.
* STYLE: Mandatory. Styling information for the reference tree or list. show: determines whether the node is displayed. col: is the node color, size: is the node size, order: is an value for ordering rows in the data frame from which the tree is produced - within one branch.
* META: Optional. Any additional information about the pattern.
* PARENT.KEY: Mandatory. Exactly one key. Ontology relation that identifies the parent pattern in the ontology tree. Mandatory.
* PARENT.NOTES: Optional. Notes on the key, if any.
* ISA.KEYS: Optional. Ontology relation. Keys of patterns that represent a category in which this pattern is contained. Semicolon separated if more than one.
* ISA.NOTES: Optional. Notes on the keys, if any.
* RESULTSFROM.KEYS: Optional. Ontology relation. Keys of patterns that create the pattern or have it as their outcome. Paired with the RESULTSIN relationship, this allows to compose processes as sequences of patterns. Semicolon separated if more than one.
* RESULTSFROM.NOTES: Optional. Notes on the keys, if any.
* GOVERNEDBY.KEYS: Optional. Ontology relation. Keys of patterns that define rules, principles, or standards for the pattern. Semicolon separated if more than one.
* GOVERNEDBY.NOTES: Optional. Notes on the keys, if any.
* COMPONENTOF.KEYS: Optional. Ontology relation. Keys of patterns that define rules, principles, or standards for the pattern. Semicolon separated if more than one. Semicolon separated if more than one.
* COMPONENTOF.NOTES: Optional. Notes on the keys, if any.
* TASK: Mandatory. The task description is the heart of the pattern: in three or four concise sentences, the main purpose of the pattern is described as a task which the pattern intends to solve, and the main benefits are listed. Constraints that reduce the effectiveness of the solution are also stated, and how those constraints can be addressed. Therefore the task description defines the reason for the pattern to exist and outlines what needs to be done to make it work well. The description is thus structured by answering the questions: (1) What is it? (2) Why is it useful or important? (3) What challenges affect it? (4) What makes it work well?
* DETAILS: Optional. This section describes details of the pattern.
* AI: Optional. This section describes specifically how AI can augment the pattern’s function and other AI concenrs. Possible negative impacts of AI may be included, as well as strategies to thwart AI use by learners if necessary. It contains prompts, where indicated and links to resources.
* IMPLEMENTATION: Optional. Clear, specific, and actionable implementation instructions are given that address problems and make use of the AI opportunities discussed above. This is a recipe of how the pattern is put into practice.
* CANBEREPLACEDWITH.KEYS: Optional. Ontology relation. Keys of patterns that can replace the pattern in a particular context. Semicolon separated if more than one.
* CANBEREPLACEDWITH.NOTES: Optional. Notes on the keys, if any.
* FIGURE.URL: Optional. URL for an image with a structured diagram that provides a graphical summary of the pattern. Semicolon separated if more than one.
* FIGURE.CAPTION: Optional. A figure caption.
* HASCOMPONENT.KEYS: Optional. Ontology relation. Keys of patterns that can function as integral parts and provide content, structure, and additional context, or compose systems. Semicolon separated if more than one.
* HASCOMPONENT.NOTES: Optional. Notes on the keys, if any.
* ALTERNATIVEFORM.KEYS: Optional. Ontology relation. Keys of patterns that describe alternative formats or modes. Semicolon separated if more than one.
* ALTERNATIVEFORM.NOTES: Optional. Notes on the keys, if any.
* RESULTSIN.KEYS: Optional. Ontology relation. Keys of patterns that are the results of the pattern. Paired with the RESULTSFROM relationship, this allows to compose processes as sequences of patterns. Semicolon separated if more than one.
* RESULTSIN.NOTES: Optional. Notes on the keys, if any.

<details>
  <summary>Other patterns that feed into here ...</summary>

<h4>Parent:</h4>
<table style="width:100%; font-size:90%; color:#555555;">
<tr><td><li><a href="https://stsyl.github.io/PLAAI/md/PMETA.md">PMETA</a> (PLAAI Metadata)</li>
</td></tr>
<tr><td><img width="980" height="1"><br/>Reference tree: IS-A relationship.</td></tr>
</table>

<h4>Is-A:</h4>
<table style="width:100%; font-size:90%; color:#555555;">
<tr><td><img width="980" height="1"><br/></td></tr>
</table>

<h4>Results from:</h4>
<table style="width:100%; font-size:90%; color:#555555;">
<tr><td><img width="980" height="1"><br/></td></tr>
</table>

<h4>Governed by:</h4>
<table style="width:100%; font-size:90%; color:#555555;">
<tr><td><img width="980" height="1"><br/></td></tr>
</table>

<h4>Component of:</h4>
<table style="width:100%; font-size:90%; color:#555555;">
<tr><td><img width="980" height="1"><br/></td></tr>
</table>
</details>

## Details:


## AI concerns:


## Implementation:


<hr style="height: 1px; background:#cee0f2; margin: 20px 0;"/>

### This Pattern could be substituted with ...
<table style="font-size:90%; color:#555555;">
<tr><td><img width="980" height="1"><br/></td></tr>
</table>

<!-- FIGURE.URL -->
<!--  FIGURE.CAPTION -->

<hr style="height: 1px; background:#cee0f2; margin: 20px 0;"/>

<details>
  <summary>Other patterns that follow from this one, or complement it ...</summary>

<h4>Components and Augmenting Patterns:</h4>
<table style="width:100%; font-size:90%; color:#555555;">
<tr><td><img width="980" height="1"><br/></td></tr>
</table>

<h4>Alternative Forms or Modes:</h4>
<table style="width:100%; font-size:90%; color:#555555;">
<tr><td><img width="980" height="1"><br/></td></tr>
</table>

<h4>Following Patterns, Results, or Outcomes:</h4>
<table style="width:100%; font-size:90%; color:#555555;">
<tr><td><img width="980" height="1"><br/></td></tr>
</table>

</details>

<hr style="height: 1px; background:#cee0f2; margin: 20px 0;"/>

<table style="width:100%; font-size:75%; color:#999999;">
<tr><td colspan="4"><img width="980" height="1"><br/>© 2023 - Boris Steipe</td></tr>
<tr>
<td><a href="https://github.com/stSyl/PLAAI">Comments and Issues</a></td>
<td><a href="https://tinyurl.com/PLAAI-wp">White Paper</a></td>
<td><a href="https://stsyl.github.io/PLAAI/PLAAI-reference.html">Reference Tree</a></td>
<td><a href="https://sentientsyllabus.substack.com">Sentient Syllabus Substack</a></td>
</tr>
</table>

<!-- END-->

