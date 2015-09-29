import std.stdio; 

interface Animal 
{
    string noise(); 
}

class Dog : Animal 
{
    string noise() {
        return "Woof!"; 
    }
}

class Poodle : Dog
{
    override string noise() {
        return "Yap " ~ Dog.noise;
    }
}

class Cat : Animal
{
    string noise() {
        return "Meow!"; 
    }
}

void pokeAnimal(Animal animal)
{
    writeln(animal.noise);
}

void main()
{
    auto dog = new Dog(); 
    auto cat = new Cat(); 
    auto poodle = new Poodle(); 
    pokeAnimal(dog); 
    pokeAnimal(cat); 
    pokeAnimal(poodle); 
}
