//
// Created by akuraru on 2014/03/25.
// Copyright (c) 2014 P.I.akura. All rights reserved.
//

#import "AVOArrayControoler.h"

@interface AKUPair : NSObject

@property(nonatomic) id first;
@property(nonatomic) id second;

+ (id)pairWithFirst:(id)f second:(id)s;

- (id)initWithFirst:(id)f second:(id)s;
@end

@implementation AKUPair
+ (id)pairWithFirst:(id)f second:(id)s {
    return [[self alloc] initWithFirst:f second:s];
}

- (id)initWithFirst:(id)f second:(id)s {
    if (self = [super init]) {
        self.first = f;
        self.second = s;
    }
    return self;
}
@end

#define pair(f, s) [AKUPair pairWithFirst:f second:s]

@interface AVOArrayController ()
@property(nonatomic) NSMutableArray *fetchedObjects;
@property(nonatomic) NSString *sectionNameKeyPath;
@property(nonatomic) NSString *sectionNameKey;
@property(nonatomic) NSArray *sections;
@property(nonatomic) id sectionsByName;
@property(nonatomic) id sectionIndexTitlesSections;
@property(nonatomic) NSPredicate *searchTerm;
@property(copy, nonatomic) NSComparisonResult (^comparator)(id, id);
@property(nonatomic) NSDictionary *arrayIndexPath;
@end

@implementation AVOArrayController {

}
- (id)initWithArray:(NSArray *)array groupedBy:(NSString *)groupedTerm withPredicate:(NSPredicate *)searchTerm sortedBy:(NSComparisonResult (^)(id, id))comparator {
    self = [super init];
    if (self) {
        self.comparator = comparator;
        if (searchTerm) {
            array = [array filteredArrayUsingPredicate:searchTerm];
        }
        self.fetchedObjects = array ? [array mutableCopy]: [@[] mutableCopy];
        [self sortArray];
        self.sectionsByName = groupedTerm;
        self.sections = [self createSections];
    }
    return self;
}

- (id)objectAtIndexPath:(NSIndexPath *)indexPath {
    return [self.sections[indexPath.section] objects][indexPath.row];
}

- (NSIndexPath *)indexPathForObject:(id)object {
    NSArray *keys = self.arrayIndexPath.allKeys;
    NSInteger index = [keys indexOfObject:object];
    if (index != NSNotFound) {
        return self.arrayIndexPath[keys[index]];
    } else {
        return nil;
    }
}


- (void)addObject:(id)object {
    [self addObjects:@[object]];
}

- (void)removeAll {
    [self controllerWillChangeContent];

    for (id object in self.fetchedObjects) {
        NSIndexPath *indexPath = [self indexPathForObject:object];
        self.sections = [self createSections];

        [self didChangeObject:object atIndexPath:indexPath forChangeType:NSFetchedResultsChangeDelete newIndexPath:nil];
    }

    self.fetchedObjects = [NSMutableArray array];

    [self controllerDidChangeContent];
}

- (void)addObjects:(NSArray *)array {
    [self controllerWillChangeContent];
    for (id object in array) {
        if ([self.searchTerm evaluateWithObject:object]) {
            continue;
        }
        [self.fetchedObjects addObject:object];
        [self sortArray];
        self.sections = [self createSections];
        NSIndexPath *indexPath = [self indexPathForObject:object];

        [self didChangeObject:object atIndexPath:nil forChangeType:NSFetchedResultsChangeInsert newIndexPath:indexPath];
    }
    [self controllerDidChangeContent];
}

- (void)updateObject:(id)object {
    if (object) {
        [self updateObjects:@[object]];
    }
}

- (void)updateObjects:(NSArray *)objects {
    [self controllerWillChangeContent];

    for (id o in objects) {
        NSIndexPath *indexPath = [self indexPathForObject:o];
        NSUInteger index = [self.fetchedObjects indexOfObject:o];
        if (indexPath != nil && index != NSNotFound) {
            self.fetchedObjects[index] = o;
            [self sortArray];
            self.sections = [self createSections];
            NSIndexPath *newIndexPath = [self indexPathForObject:o];

            NSFetchedResultsChangeType type = ([indexPath isEqual:newIndexPath]) ? NSFetchedResultsChangeUpdate : NSFetchedResultsChangeMove;
            [self didChangeObject:o atIndexPath:indexPath forChangeType:type newIndexPath:newIndexPath];
        }
    }

    [self controllerDidChangeContent];
}

- (void)removeObject:(id)object {
    [self controllerWillChangeContent];

    NSIndexPath *indexPath = [self indexPathForObject:object];
    if (indexPath) {
    [self.fetchedObjects removeObject:object];
        self.sections = [self createSections];

        [self didChangeObject:object atIndexPath:indexPath forChangeType:NSFetchedResultsChangeDelete newIndexPath:nil];
    }

    [self controllerDidChangeContent];
}

- (void)didChangeObject:(id)object atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    if ([self.delegate respondsToSelector:@selector(controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:)]) {
        [self.delegate controller:(id) self didChangeObject:object atIndexPath:indexPath forChangeType:type newIndexPath:newIndexPath];
    }
}

- (void)controllerWillChangeContent {
    if ([self.delegate respondsToSelector:@selector(controllerWillChangeContent:)]) {
        [self.delegate controllerWillChangeContent:(id) self];
    }
}

- (void)controllerDidChangeContent {
    if ([self.delegate respondsToSelector:@selector(controllerDidChangeContent:)]) {
        [self.delegate controllerDidChangeContent:(id) self];
    }
}

- (NSArray *)sortKeysForTerm:(NSString *)term {
    return [term componentsSeparatedByString:@","];
}

- (NSArray *)sortDescriptors:(NSArray *)sortKeys ascending:(BOOL)ascending {
    NSMutableArray *sortDescriptors = [[NSMutableArray alloc] init];
    for (NSString *sortKey in sortKeys) {
        [sortDescriptors addObject:[[NSSortDescriptor alloc] initWithKey:sortKey ascending:ascending]];
    }
    return sortDescriptors;
}

- (NSArray *)createSections {
    NSString *keyPath = self.sectionsByName;
    if (keyPath == nil) {
        NSArray *result = @[[self createSectionInfo:nil objects:self.fetchedObjects]];
        [self createArrayIndexPath:result];
        return result;
    }

    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    for (id o in self.fetchedObjects) {
        id value = [o valueForKeyPath:keyPath];
        AKUPair *pair = dictionary[value];
        if (pair) {
            [pair.second addObject:o];
        } else {
            id sortValue = [o valueForKeyPath:keyPath];
            dictionary[value] = [AKUPair pairWithFirst:sortValue second:[NSMutableArray arrayWithObject:o]];
        }
    }
    NSArray *keys = [dictionary.allKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [[dictionary[obj1] first] compare:[dictionary[obj2] first]];
    }];

    NSMutableArray *result = [NSMutableArray array];
    [keys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        AKUPair *pair = dictionary[obj];
        [result addObject:[self createSectionInfo:obj objects:[pair second]]];
    }];
    [self createArrayIndexPath:result];
    return result;
}

- (AVOArrayControllerSectionInfo *)createSectionInfo:(NSString *)name objects:(NSArray *)objects {
    AVOArrayControllerSectionInfo *info = [[AVOArrayControllerSectionInfo alloc] init];
    info.name = name;
    info.indexTitle = name;
    info.objects = objects;
    return info;
}

- (void)createArrayIndexPath:(NSArray *)result {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    __block NSUInteger index = 0;
    [result enumerateObjectsUsingBlock:^(AVOArrayControllerSectionInfo *info, NSUInteger idx, BOOL *stop) {
        for (NSUInteger row = 0, _len = info.numberOfObjects; row < _len; row++, index++) {
            dict[self.fetchedObjects[index]] = [NSIndexPath indexPathForRow:row inSection:idx];
        }
    }];
    self.arrayIndexPath = dict;
}

- (void)sortArray {
    if (self.comparator) {
        [self.fetchedObjects sortUsingComparator:self.comparator];
    }
}
@end

@implementation AVOArrayControllerSectionInfo
- (instancetype)initWithName:(NSString *)name objects:(NSArray *)objects {
    self = [super init];
    if (self) {
        self.name = name;
        self.indexTitle = name;
        self.objects = objects;
    }
    return self;
}
- (NSUInteger)numberOfObjects {
    return self.objects.count;
}

- (BOOL)isEqual:(id)object {
    return ((self.name == nil && [object name] == nil) || [[self name] isEqualToString:[object name]])
            && ((self.indexTitle == nil && [object indexTitle] == nil) || [[self indexTitle] isEqualToString:[object indexTitle]])
            && (([self objects] == nil && [object objects] == nil) || [[self objects] isEqual:[object objects]]);
}
@end
