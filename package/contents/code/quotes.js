.pragma library

// Short public-domain quotes; one per day, picked by day of year.
var QUOTES = [
    ["The impediment to action advances action. What stands in the way becomes the way.", "Marcus Aurelius"],
    ["Luck is what happens when preparation meets opportunity.", "Seneca"],
    ["A journey of a thousand miles begins with a single step.", "Lao Tzu"],
    ["It does not matter how slowly you go as long as you do not stop.", "Confucius"],
    ["Simplicity is the ultimate sophistication.", "Leonardo da Vinci"],
    ["We are what we repeatedly do. Excellence, then, is not an act, but a habit.", "Will Durant, on Aristotle"],
    ["No man ever steps in the same river twice.", "Heraclitus"],
    ["First say to yourself what you would be; and then do what you have to do.", "Epictetus"],
    ["Go confidently in the direction of your dreams.", "Henry David Thoreau"],
    ["Do not wait to strike till the iron is hot; but make it hot by striking.", "William Butler Yeats"],
    ["The secret of getting ahead is getting started.", "Mark Twain"],
    ["Well done is better than well said.", "Benjamin Franklin"],
    ["Knowing is not enough; we must apply. Willing is not enough; we must do.", "Johann Wolfgang von Goethe"],
    ["What you do today can improve all your tomorrows.", "Ralph Marston"],
    ["Nothing is particularly hard if you divide it into small jobs.", "Henry Ford"],
    ["The best way out is always through.", "Robert Frost"],
    ["Adopt the pace of nature: her secret is patience.", "Ralph Waldo Emerson"],
    ["He who has a why to live can bear almost any how.", "Friedrich Nietzsche"],
    ["Waste no more time arguing what a good man should be. Be one.", "Marcus Aurelius"],
    ["While we are postponing, life speeds by.", "Seneca"],
    ["The man who moves a mountain begins by carrying away small stones.", "Confucius"],
    ["Be kind, for everyone you meet is fighting a hard battle.", "Ian Maclaren"],
    ["Little by little, one travels far.", "J. R. R. Tolkien"],
    ["Energy and persistence conquer all things.", "Benjamin Franklin"],
    ["Make each day your masterpiece.", "John Wooden"],
    ["Begin at once to live, and count each separate day as a separate life.", "Seneca"],
    ["The mind is everything. What you think you become.", "attributed to the Buddha"],
    ["Whatever you are, be a good one.", "Abraham Lincoln"],
    ["Imagination is more important than knowledge.", "Albert Einstein"],
    ["To live is the rarest thing in the world. Most people exist, that is all.", "Oscar Wilde"],
    ["Not all those who wander are lost.", "J. R. R. Tolkien"],
    ["The quieter you become, the more you are able to hear.", "Rumi"],
    ["Do what you can, with what you have, where you are.", "Theodore Roosevelt"],
    ["Happiness depends upon ourselves.", "Aristotle"],
    ["The obstacle is the path.", "Zen proverb"],
    ["Fall seven times, stand up eight.", "Japanese proverb"],
    ["Rest is not idleness.", "John Lubbock"],
    ["Every moment is a fresh beginning.", "T. S. Eliot"],
    ["Stay hungry, stay foolish.", "The Whole Earth Catalog"],
    ["Well begun is half done.", "Aristotle"]
];

function forDate(d) {
    var start = new Date(d.getFullYear(), 0, 0);
    var day = Math.floor((d - start) / 86400000);
    return QUOTES[(day + d.getFullYear()) % QUOTES.length];
}
