EatMe
=====

***Code Examples in Wonderland***

<!--
Examples are text; Must edit!
Edit and tinker my examples!
-->

<blockquote>
<p>Soon her eye fell on a little glass box that was lying under the table: she
opened it, and found in it a very small cake, on which the words “<strong>EAT
ME</strong>” were beautifully marked in currants.
“Well, I’ll eat it,” said Alice, “and if it makes me grow larger, I can reach
the key; and if it makes me grow smaller, I can creep under the door; so either
way I’ll get into the garden, and I don’t care which happens!”
</p>
<footer>
&mdash; <em>Alice’s Adventures in Wonderland by Lewis Carroll</em>
</footer>
</blockquote>


# Synopsis

In Markdown, write a code example like this:


````
```yaml-to-json
name: Alice
place: Wonderland
```
````

It renders like this:

![...](text.jpg)

Click on it and it turns into this:

![...](eatme.jpg)


# Description

In online documentation, all code examples in that involve inputs and outputs should be interactive.
It should be trivial for a documentation author to create interactive examples.
The interactive layouts should be completely and easily configurable.

[EatMe](https://eatme.dev) is a project to make this a reality.

Let's say you configure EatMe like this:
```yaml
coffee-js:
- name: CoffeeScript
  slug: cs
  type: input
- name: JavaScript
  from: cs
  func: compileCoffee
```

When you write an example like:
````
```coffee-js
alert "I'm #{if ok() then '' else 'not '}ok!"
```
````

You see the CoffeeScript code and the JavaScript it compiles to as a nicely formatted example.
When you click on it, the CoffeeScript becomes editable so that you can try out variations.

This is actually how the [CoffeeScript website](https://coffeescript.org) examples work.
But with EatMe, everything is configurable and easily embeddable into lots of documentation layouts.

[Fiddle](https://jsfiddle.net/), [CodePen](https://codepen.io/) and [CodeSandbox](https://codesandbox.io/) let you create examples for HTML/JS/CSS on their sites.

EatMe can be configured to make those kind of examples inline in your docs or web pages.
But it can also be configured in any arrangement imaginable, with any kinds of inputs and outputs.
