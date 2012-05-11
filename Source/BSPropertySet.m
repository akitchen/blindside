#import "BSPropertySet.h"
#import "BSProperty.h"
#import "NSObject+Blindside.h"

#import <objc/runtime.h>

@interface BSPropertySet ()
@property (nonatomic, assign) Class owningClass;
@property (nonatomic, retain) NSMutableArray *properties;

- (id)initWithClass:(Class)owningClass properties:(NSMutableArray *)properties;

- (void)merge:(BSPropertySet *)propertySet;

@end

@implementation BSPropertySet

@synthesize owningClass = owningClass_, properties = properties_;

+ (BSPropertySet *)propertySetWithClass:(Class)owningClass propertyNames:(NSString *)property1, ... {
    NSMutableArray *bsProperties = [NSMutableArray array];
    if (property1) {
        [bsProperties addObject:[BSProperty propertyWithClass:owningClass propertyName:property1]];

        va_list argList;
        id propertyName = nil;
        va_start(argList, property1);
        while ((propertyName = va_arg(argList, id))) {
            [bsProperties addObject:[BSProperty propertyWithClass:owningClass propertyName:propertyName]];
        }
        va_end(argList);
    }

    BSPropertySet *propertySet = [[[BSPropertySet alloc] initWithClass:owningClass properties:bsProperties] autorelease];
    
    Class superclass = class_getSuperclass(owningClass);
    if (superclass != nil) {
        BSPropertySet *superclassPropertySet = [superclass blindsideProperties];
        [propertySet merge:superclassPropertySet];
    }
    
    return propertySet;
};

- (id)initWithClass:(Class)owningClass properties:(NSMutableArray *)properties {
    if (self = [super init]) {
        self.owningClass = owningClass;
        self.properties = properties;
    }
    return self;
}

- (void)dealloc {
    self.properties = nil;
    [super dealloc];
}

- (void)bindProperty:(NSString *)propertyName toKey:(id)key {
    for (BSProperty *property in self.properties) {
        if (property.propertyName == propertyName) {
            property.injectionKey = key;
        }
    }
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len {
    return [self.properties countByEnumeratingWithState:state objects:stackbuf count:len];
}

- (BOOL)hasProperty:(BSProperty *)property {
    for (BSProperty *myProperty in self.properties) {
        if (myProperty.propertyName == property.propertyName) {
            return YES;
        }
    }
    return NO;
}

- (void)addProperty:(BSProperty *)property {
    [self.properties addObject:property];
}

- (void)merge:(BSPropertySet *)propertySet {
    for (BSProperty *property in propertySet.properties) {
        if (![self hasProperty:property]) {
            [self addProperty:property];
        }
    }
}

@end