# PHPSerialization

This project started out of a random Freelancer.com project post. The customer was requesting to convert a php serialized string to json and he wanted the project to be in C#. The project also referenced a [C# PHP Serialization](https://sourceforge.net/projects/csphpserial/) a.k.a *Sharp Serialization Library* that might offer some insight to achieve his request. 

Since the Sharp Serialization Library was already written in C#, I simply converted the C# class to a PowerShell class to practice writing classes in PowerShell. And I was bored. 

As it turned out, I tested a few serialized php arrays and they worked. After doing some more research, I came across another article by [Gordon Breuer](https://gordon-breuer.de/unknown/2011/05/04/php-un-serialize-with-c.html), who decided to use List<> objects (instead of Arraylists) and Dictionary<> object (instead of Hashtables) to cover all basis. I decided to use with his code instead. 

There are a few things to note in my preliminary testing:
 * I haven't tried to serialized php data; only deserialize/unserialize 
 * This only works on simple data types and structures such as arrays/hashtables. Any nested hashtables, jagged/multi-dimensional arrays will have to be done with additional code. 

## Examples 

### Example 1: A serialized PHP array containing strings, an integer and a bool response
To use the PHPSerialization PowerShell Class, download the .psm1 file and either put it in one of your module locations or your desired location. Import-Module does not work. Instead, you will have to use the keyword "Using" and "Module" to get PS to recognize the class:

```
Using Module "C:\Users\Nicos\Documents\WindowsPowerShell\Modules\PHPSerialization\PHPSerializationClass.psm1"
```

Next, take a php serialized code and wrap it in a here string:

```
$phpstring = @"
a:9:{s:8:"playerId";s:12:"omp-id-84560";s:4:"type";s:5:"audio";s:6:"player";s:5:"html5";s:9:"timestamp";N;s:4:"page";s:59:"https://fakeaudiosite.com/view.php?id=123456789&section=1.0";s:3:"src";s:57:"https://fakeaudiosite/pluginfile.php/22639/14j_aug041.mp3";s:7:"browser";s:6:"chrome";s:8:"isMobile";b:0;s:5:"value";i:10;}"
"@
```

To see the results outputted directly to PS, type:

```
[PHPSerialization]::new().Deserialize($phpstring) 
```
