#include<iostream>

class A
{
    public:
    void run()
    {
        std::cout << "Hello, World!"; 
    }
};

class B : private A 
{
    public:
    void run()
    {
        std::cout << "Hello, B";
        A::run();
    }
};


int main()
{
    B x; 
    x.run();
    return 0;
}
